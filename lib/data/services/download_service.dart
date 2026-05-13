import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart' as crypto;
import 'package:logging/logging.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/data/services/models/download_model.dart';

class DownloadService extends ChangeNotifier {
  final _log = Logger('DownloadService');

  final Map<String, List<DownloadModel>> _activeDownloads = {};

  void clearTrackedModels(String tag) {
    _activeDownloads.remove(tag);
    notifyListeners();
  }

  double? getProgress(String tag) {
    final tasks = _activeDownloads[tag];
    if (tasks == null || tasks.isEmpty) return null;

    int totalExpected = 0;
    int totalDownloaded = 0;
    for (final task in tasks) {
      totalExpected += task.expectedSize;
      totalDownloaded += task.downloadedSize;
    }

    if (totalExpected == 0) return null;
    return totalDownloaded / totalExpected;
  }

  bool isDownloading(String tag) {
    final tasks = _activeDownloads[tag];
    if (tasks == null || tasks.isEmpty) return false;
    return tasks.any(
      (t) =>
          t.status == DownloadStatus.downloading ||
          t.status == DownloadStatus.pending,
    );
  }

  Future<Result<void>> download(DownloadModel model) async {
    try {
      final appData = await getApplicationSupportDirectory();
      final fullPath = p.join(appData.path, model.path);

      final file = File(fullPath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final request = http.Request('GET', Uri.parse(model.url));
      _log.finer('Starting download: ${model.url} -> ${model.path}');
      final response = await http.Client().send(request);

      model.status = DownloadStatus.downloading;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final sink = file.openWrite();
        int total = 0;
        int lastNotifyTime = DateTime.now().millisecondsSinceEpoch;
        await for (final chunk in response.stream) {
          sink.add(chunk);
          total += chunk.length;
          model.downloadedSize = total;
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastNotifyTime > 100) {
            lastNotifyTime = now;
            notifyListeners();
          }
        }
        await sink.close();
        model.status = DownloadStatus.finished;
        notifyListeners();
        _log.finer('Download finished: ${model.path} (Size: total bytes)');
        return const Result.success(null);
      } else {
        model.status = DownloadStatus.failed;
        notifyListeners();
        _log.finer(
          'Download failed: ${model.path} (HTTP ${response.statusCode})',
        );
        return Result.failure(
          Exception('Failed to download: HTTP ${response.statusCode}'),
        );
      }
    } catch (e) {
      model.status = DownloadStatus.failed;
      notifyListeners();
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
        model.status = DownloadStatus.finished;
        model.downloadedSize = await file.length();
        _log.finer(
          'File exists, no SHA1 provided (assuming valid): ${model.path}',
        );
        notifyListeners();
        return const Result.success(true);
      }

      final stream = file.openRead();
      final digest = await crypto.sha1.bind(stream).first;

      if (digest.toString() == model.sha1) {
        model.status = DownloadStatus.finished;
        model.downloadedSize = await file.length();
        _log.finer('File SHA1 matches: ${model.path}');
        notifyListeners();
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

  Future<Result<void>> downloadIfMissing(DownloadModel model) async {
    final downloadedResult = await isDownloaded(model);
    switch (downloadedResult) {
      case Success<bool>(value: final isDownloaded):
        if (!isDownloaded) {
          return download(model);
        }
        return const Result.success(null);
      case Failure<bool>():
        return Result.failure(downloadedResult.error);
    }
  }

  Future<Result<void>> downloadAll(List<DownloadModel> models) async {
    for (final model in models) {
      if (model.tag != null) {
        if (!(_activeDownloads[model.tag!]?.contains(model) ?? false)) {
          _activeDownloads.putIfAbsent(model.tag!, () => []).add(model);
        }
      }
    }
    notifyListeners();

    for (final model in models) {
      final result = await downloadIfMissing(model);
      if (result is Failure<void>) {
        return result;
      }
    }
    return const Result.success(null);
  }
}
