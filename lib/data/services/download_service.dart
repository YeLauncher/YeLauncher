import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/utilities/result.dart';

class DownloadService {
  final _log = Logger('DownloadService');
  final http.Client _client;

  DownloadService({http.Client? client}) : _client = client ?? http.Client();

  Future<Result<void>> download(
    DownloadModel model, {
    void Function(int downloadedBytes, int? totalBytes)? onProgress,
  }) async {
    try {
      final appData = await getApplicationSupportDirectory();
      final fullPath = p.join(appData.path, model.path);

      final file = File(fullPath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final request = http.Request('GET', Uri.parse(model.url));
      _log.finer('Starting download: ${model.url} -> ${model.path}');
      final response = await _client.send(request);

      // model.status = DownloadStatus.downloading;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final sink = file.openWrite();
        int total = 0;
        int lastNotifyTime = DateTime.now().millisecondsSinceEpoch;
        await for (final chunk in response.stream) {
          sink.add(chunk);
          total += chunk.length;
          onProgress?.call(total, model.expectedSize ?? response.contentLength);
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastNotifyTime > 100) {
            lastNotifyTime = now;
            // notifyListeners();
          }
        }
        await sink.close();
        // model.status = DownloadStatus.finished;
        // notifyListeners();
        _log.finer('Download finished: ${model.path} (Size: total bytes)');
        return const Result.success(null);
      } else {
        // model.status = DownloadStatus.failed;
        // notifyListeners();
        _log.finer(
          'Download failed: ${model.path} (HTTP ${response.statusCode})',
        );
        return Result.failure(
          Exception('Failed to download: HTTP ${response.statusCode}'),
        );
      }
    } catch (e) {
      // model.status = DownloadStatus.failed;
      // notifyListeners();
      _log.finer('Download exception: ${model.path} ($e)');
      return Result.failure(Exception('Failed to download: $e'));
    }
  }

  Future<Result<bool>> isDownloaded(DownloadModel model) async {
    try {
      _log.finer('Checking if downloaded: ${model.path}');
      final appData = await getApplicationSupportDirectory();
      final fullPath = p.join(appData.path, model.path);

      final file = File(fullPath);
      if (!await file.exists()) {
        return const Result.success(false);
      }

      if (model.sha1.isEmpty) {
        // model.status = DownloadStatus.finished;
        // model.downloadedSize = await file.length();
        await file.length();
        _log.finer(
          'File exists, no SHA1 provided (assuming valid): ${model.path}',
        );
        // notifyListeners();
        return const Result.success(true);
      }

      final expectedSha1 = model.sha1;
      
      final stream = file.openRead();
      final digest = await crypto.sha1.bind(stream).first;

      if (digest.toString() == expectedSha1) {
        // model.status = DownloadStatus.finished;
        // model.downloadedSize = await file.length();
        await file.length();
        _log.finest('File SHA1 matches: ${model.path}');
        // notifyListeners();
        return const Result.success(true);
      }
      _log.finer(
        'File SHA1 mismatch for ${model.path} (expected: ${model.sha1}, got: $digest)',
      );
      return const Result.success(false);
    } catch (e) {
      _log.finer('Check download exception: ${model.path} ($e)');
      return Result.failure(Exception('Failed to check download: $e'));
    }
  }

  Future<Result<void>> downloadIfMissing(
    DownloadModel model, {
    void Function(int downloadedBytes, int? totalBytes)? onProgress,
  }) async {
    final downloadedResult = await isDownloaded(model);
    switch (downloadedResult) {
      case Success<bool>(value: final isDownloaded):
        if (!isDownloaded) {
          return download(model, onProgress: onProgress);
        } else {
          // File is already downloaded. Fetch local size and instantly report 100% progress
          // so the batch download differential math works correctly.
          try {
            final appData = await getApplicationSupportDirectory();
            final file = File(p.join(appData.path, model.path));
            final size = await file.length();
            onProgress?.call(size, size);
          } catch (e) {
            _log.finer('Failed to get size for existing file: ${model.path}');
            onProgress?.call(0, null);
          }
          return const Result.success(null);
        }
      case Failure<bool>():
        return Result.failure(downloadedResult.error);
    }
  }

  Future<Result<void>> downloadAll(
    List<DownloadModel> models, {
    void Function(int totalDownloadedBytes, int? totalExpectedBytes)?
    onProgress,
  }) async {
    int accumulatedTotalBytes = 0;
    bool hasUnknownTotal = false;

    // --- PASS 1: PRE-FLIGHT SIZE CHECK ---
    _log.finer('Starting pre-flight size check for ${models.length} files...');
    final checkBatchSize = 50;
    for (int i = 0; i < models.length; i += checkBatchSize) {
      final batch = models.skip(i).take(checkBatchSize).toList();
      final futures = batch.map((model) async {
        if (model.expectedSize != null) {
          return model.expectedSize!;
        }

        final downloadedResult = await isDownloaded(model);
        if (downloadedResult is Success<bool> && downloadedResult.value) {
          // File exists locally, check its size on disk
          try {
            final appData = await getApplicationSupportDirectory();
            final file = File(p.join(appData.path, model.path));
            return await file.length();
          } catch (_) {
            return null; // Unknown total
          }
        } else {
          // File needs downloading, ask the server for Content-Length via HEAD request if not provided
          return await _getRemoteFileSize(model.url);
        }
      });
      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) {
          accumulatedTotalBytes += result;
        } else {
          hasUnknownTotal = true;
        }
      }
    }

    final grandTotalBytes = hasUnknownTotal ? null : accumulatedTotalBytes;
    int accumulatedDownloadedBytes = 0;

    // Fire initial progress in case fetching sizes took a moment
    onProgress?.call(accumulatedDownloadedBytes, grandTotalBytes);

    // --- PASS 2: ACTUAL DOWNLOAD ---
    final batchSize = 20;
    for (int i = 0; i < models.length; i += batchSize) {
      final batch = models.skip(i).take(batchSize).toList();
      final futures = batch.map((model) async {
        int lastReportedDownloaded = 0;
        final result = await downloadIfMissing(
          model,
          onProgress: (downloadedBytes, _) {
            // Calculate differential progress for the current file
            int diffDownloaded = downloadedBytes - lastReportedDownloaded;
            accumulatedDownloadedBytes += diffDownloaded;
            lastReportedDownloaded = downloadedBytes;

            // Emit unified progress using the pre-calculated grand total
            onProgress?.call(accumulatedDownloadedBytes, grandTotalBytes);
          },
        );
        return result;
      });

      final results = await Future.wait(futures);
      for (final result in results) {
        if (result is Failure<void>) {
          return result; // Fast-fail
        }
      }
    }

    return const Result.success(null);
  }

  Future<int?> _getRemoteFileSize(String url) async {
    try {
      final response = await _client.head(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLengthStr = response.headers['content-length'];
        if (contentLengthStr != null) {
          return int.tryParse(contentLengthStr);
        }
      }
    } catch (e) {
      _log.finer('Failed to fetch remote size via HEAD for $url: $e');
    }
    return null;
  }
}
