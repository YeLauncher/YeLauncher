import 'dart:io';

import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  Future<void> extractNatives(
    String absoluteJarPath,
    String absoluteOutputDir,
  ) async {
    await Isolate.run(() async {
      final jarFile = File(absoluteJarPath);
      if (!await jarFile.exists()) {
        throw Exception('Native JAR not found: $absoluteJarPath');
      }

      final bytes = await jarFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final name = file.name.toLowerCase();
          if (name.endsWith('.dll') ||
              name.endsWith('.so') ||
              name.endsWith('.dylib') ||
              name.endsWith('.jnilib')) {
            final outFile = File(p.join(absoluteOutputDir, p.basename(file.name)));
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
          }
        }
      }
    });
  }

  Future<String> getLibraryDirectory() async {
    return await getAbsolutePath(['libraries']);
  }

  Future<String> getLibraryPath(String libraryRelativePath) async {
    return await getAbsolutePath(['libraries', libraryRelativePath]);
  }

  Future<String> getAssetDirectory() async {
    return await getAbsolutePath(['assets']);
  }

  Future<String> getGameDirectory(String id) async {
    return await getAbsolutePath(['instances', id]);
  }

  Future<String> getNativesDirectory(String id) async {
    return await getAbsolutePath(['instances', id, 'natives']);
  }

  Future<String> getClientJarPath(String id) async {
    return await getAbsolutePath(['versions', id, '$id.jar']);
  }

  Future<String> getJavaExecutablePath(String id) async {
    // If the launcher manages its own Java runtimes, this would resolve to the downloaded
    // runtime path (e.g. runtimes/$id/bin/java). As a fallback, we return the system java.
    return 'java';
  }

  Future<void> createDirectory(String relativePath) async {
    final fullPath = await getAbsolutePath([relativePath]);
    final dir = Directory(fullPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<String> getAbsolutePath(List<String> paths) async {
    final localPath = await _localPath;
    return p.joinAll([localPath, ...paths]);
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }
}