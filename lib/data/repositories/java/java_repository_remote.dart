import 'dart:io';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:logging/logging.dart';

class JavaRepositoryRemote implements JavaRepository {
  final _log = Logger('JavaRepositoryRemote');

  String get _cpuArch {
    final abiString = Abi.current().toString();
    if (abiString.contains('arm64')) return 'aarch64';
    if (abiString.contains('x64')) return 'x64';
    if (abiString.contains('ia32')) return 'x86';
    return 'x64'; // fallback
  }

  String get _os {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return 'windows';
  }

  String get _ext {
    return Platform.isWindows ? 'zip' : 'tar.gz';
  }

  Future<Directory> _getJavaDir(int version) async {
    final appData = await getApplicationSupportDirectory();
    return Directory(p.join(appData.path, 'java', version.toString()));
  }

  @override
  Future<Result<bool>> isInstalled(int version) async {
    try {
      final javaDir = await _getJavaDir(version);
      if (!await javaDir.exists()) return Result.success(false);

      final execPath = await _findExecutable(javaDir);
      return Result.success(execPath != null);
    } catch (e) {
      return Result.failure(
        Exception('Failed to check Java install status: $e'),
      );
    }
  }

  @override
  Future<Result<String>> getJavaExecutablePath(int version) async {
    try {
      final javaDir = await _getJavaDir(version);
      if (!await javaDir.exists()) {
        return Result.failure(Exception('Java $version is not installed.'));
      }
      final execPath = await _findExecutable(javaDir);
      if (execPath == null) {
        return Result.failure(
          Exception('Java $version executable not found in $javaDir'),
        );
      }
      return Result.success(execPath);
    } catch (e) {
      return Result.failure(Exception('Failed to get Java path: $e'));
    }
  }

  @override
  Future<Result<void>> install(
    int version, {
    void Function(double)? onProgress,
  }) async {
    try {
      final url =
          'https://corretto.aws/downloads/latest/amazon-corretto-$version-$_cpuArch-$_os-jdk.$_ext';
      _log.info('Downloading Java $version from $url');

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        return Result.failure(
          Exception('Failed to download Java $version: ${response.statusCode}'),
        );
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;
      final bytesBuilder = BytesBuilder();

      await for (final chunk in response.stream) {
        bytesBuilder.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(downloadedBytes / contentLength);
        }
      }

      final javaDir = await _getJavaDir(version);
      if (await javaDir.exists()) {
        await javaDir.delete(recursive: true);
      }
      await javaDir.create(recursive: true);

      if (_ext == 'zip') {
        final archive = ZipDecoder().decodeBytes(bytesBuilder.toBytes());
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final outFile = File(p.join(javaDir.path, filename));
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
          } else {
            await Directory(
              p.join(javaDir.path, filename),
            ).create(recursive: true);
          }
        }
      } else {
        // tar.gz
        final archive = TarDecoder().decodeBytes(
          GZipDecoder().decodeBytes(bytesBuilder.toBytes()),
        );
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final outFile = File(p.join(javaDir.path, filename));
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);

            // On unix, make the executable file truly executable
            if (filename.endsWith('bin/java')) {
              if (Platform.isLinux || Platform.isMacOS) {
                await Process.run('chmod', ['+x', outFile.path]);
              }
            }
          } else {
            await Directory(
              p.join(javaDir.path, filename),
            ).create(recursive: true);
          }
        }
      }

      _log.info('Successfully installed Java $version');
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to install Java $version: $e'));
    }
  }

  Future<String?> _findExecutable(Directory dir) async {
    final execName = Platform.isWindows ? 'java.exe' : 'java';

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path) == execName) {
        if (p.basename(entity.parent.path) == 'bin') {
          return entity.path;
        }
      }
    }
    return null;
  }
}
