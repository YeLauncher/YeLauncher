import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/services/api/forge_api_client.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/file_service.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class ForgeRepositoryRemote implements ForgeRepository {
  final _log = Logger('ForgeRepositoryRemote');
  final ForgeApiClient _apiClient;
  final DownloadService downloadService;
  final FileService _fileService;
  final Map<String, _ForgeInstallerMetadata> _metadataCache = {};

  ForgeRepositoryRemote({
    required ForgeApiClient apiClient,
    required this.downloadService,
    required FileService fileService,
  })  : _apiClient = apiClient,
        _fileService = fileService;

  @override
  String get id => 'forge';

  @override
  String get name => 'Forge';

  @override
  String get icon => 'assets/forge.svg';

  @override
  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  ) async {
    try {
      _log.fine('Loading Forge versions for Minecraft $minecraftVersion');
      final versions = await _apiClient.getVersions(minecraftVersion);
      _log.fine(
        'Loaded ${versions.length} Forge version candidates for Minecraft $minecraftVersion',
      );
      final mappedVersions = versions.map((apiModel) {
        return ModLoaderVersionModel(
          id: 'forge-${apiModel.version}',
          version: apiModel.version,
          type: 'release',
        );
      }).toList();
      return Result.success(mappedVersions);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String?>> getLatestVersion(String minecraftVersion) async {
    try {
      _log.fine('Loading latest Forge version for Minecraft $minecraftVersion');
      return Result.success(
        await _apiClient.getLatestVersion(minecraftVersion),
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String?>> getRecommendedVersion(String minecraftVersion) async {
    try {
      _log.fine(
        'Loading recommended Forge version for Minecraft $minecraftVersion',
      );
      return Result.success(
        await _apiClient.getRecommendedVersion(minecraftVersion),
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<String>>> getLibrariesPath(String id) async {
    try {
      _log.fine('Resolving Forge libraries for $id');
      final forgeId = await _resolveInstalledForgeId(id);
      if (forgeId == null) {
        _log.warning('Forge libraries lookup failed for $id: no installed version found');
        return Result.failure(
          Exception('Forge version JSON not found for $id'),
        );
      }

      final versionJson = await _readVersionJson(forgeId);
      if (versionJson == null) {
        _log.warning('Forge libraries lookup failed for $forgeId: version JSON missing');
        return Result.failure(
          Exception('Forge version JSON not found for $forgeId'),
        );
      }

      final paths = _extractLibraryPaths(versionJson);
      _log.fine('Resolved ${paths.length} Forge libraries for $forgeId');
      return Result.success(paths);
    } catch (e) {
      _log.severe('Failed to read Forge libraries for $id: $e');
      return Result.failure(Exception('Failed to read Forge libraries: $e'));
    }
  }

  @override
  Future<Result<void>> install(
    String id, {
    String? minecraftVersion,
    void Function(int, int?)? onProgress,
  }) async {
    try {
      final target = _parseInstallTarget(id, minecraftVersion);
      if (target == null) {
        _log.warning('Forge install aborted for $id: minecraftVersion missing');
        return Result.failure(
          Exception('minecraftVersion is required for Forge installation'),
        );
      }

      _log.info(
        'Installing Forge for Minecraft ${target.minecraftVersion} using Forge ${target.forgeVersion}',
      );
      final forgeVersion = target.forgeVersion;
      final result = await _installForge(
        minecraftVersion: target.minecraftVersion,
        forgeVersion: forgeVersion,
        onProgress: onProgress,
      );
      return result;
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<bool>> isInstalled(String id) async {
    try {
      _log.fine('Checking Forge installation status for $id');
      final forgeId = await _resolveInstalledForgeId(id);
      if (forgeId == null) {
        _log.fine('Forge installation not found for $id');
        return const Result.success(false);
      }

      final versionJson = await _readVersionJson(forgeId);
      if (versionJson == null) {
        _log.fine('Forge version JSON missing for $forgeId');
        return const Result.success(false);
      }

      final clientJarPath = await _fileService.getAbsolutePath([
        'versions',
        forgeId,
        '$forgeId.jar',
      ]);

      if (!await File(clientJarPath).exists()) {
        _log.fine('Forge installation check for $forgeId: client jar is missing');
        return const Result.success(false);
      }

      final libraryPaths = _extractLibraryPaths(versionJson);
      for (final libPath in libraryPaths) {
        final fullPath = await _fileService.getLibraryPath(libPath);
        if (!await File(fullPath).exists()) {
          _log.fine('Forge installation check for $forgeId: library $libPath is missing');
          return const Result.success(false);
        }
      }

      _log.fine('Forge installation check for $forgeId: all files exist');
      return const Result.success(true);
    } catch (e) {
      _log.warning('Failed to check Forge installation for $id: $e');
      return Result.failure(Exception('Failed to check Forge installation: $e'));
    }
  }

  @override
  Future<Result<void>> processInstallation(
    String id,
    String minecraftVersion,
  ) async {
    try {
      _log.info('Processing Forge installation for $id and Minecraft $minecraftVersion');
      final target = _parseInstallTarget(id, minecraftVersion);
      if (target == null) {
        _log.warning('Forge processInstallation aborted for $id: minecraftVersion missing');
        return Result.failure(
          Exception('minecraftVersion is required for Forge installation'),
        );
      }

      return _installForge(
        minecraftVersion: target.minecraftVersion,
        forgeVersion: target.forgeVersion,
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<void>> _installForge({
    required String minecraftVersion,
    required String forgeVersion,
    void Function(int, int?)? onProgress,
  }) async {
    final forgeId = _forgeId(minecraftVersion, forgeVersion);
    final tempDir = await Directory.systemTemp.createTemp('yelauncher-forge-');
    try {
      _log.info('Starting Forge install for $forgeId');
      final installerPath = p.join(
        tempDir.path,
        'forge-$minecraftVersion-$forgeVersion-installer.jar',
      );

      _log.fine('Downloading Forge installer to $installerPath');
      final downloadResult = await _downloadInstaller(
        minecraftVersion: minecraftVersion,
        forgeVersion: forgeVersion,
        destinationPath: installerPath,
        onProgress: onProgress,
      );
      if (downloadResult is Failure<void>) {
        _log.warning('Forge installer download failed for $forgeId: ${downloadResult.error}');
        return Result.failure(downloadResult.error);
      }

      _log.fine('Extracting installer metadata for $forgeId');
      final extractedResult = await _extractForgeInstaller(
        installerPath: installerPath,
        forgeId: forgeId,
      );
      if (extractedResult is Failure<void>) {
        _log.warning('Forge installer extraction failed for $forgeId: ${extractedResult.error}');
        return Result.failure(extractedResult.error);
      }

      final metadata = _metadataCache[forgeId];
      if (metadata == null) {
        _log.severe('Forge metadata cache miss after extraction for $forgeId');
        return Result.failure(
          Exception('Failed to cache Forge installer metadata for $forgeId'),
        );
      }

      _log.fine('Persisting Forge metadata for $forgeId');
      final persistedResult = await _persistForgeMetadata(
        forgeId: forgeId,
        installProfile: metadata.installProfile,
        versionJson: metadata.versionJson,
      );
      if (persistedResult is Failure<void>) {
        _log.warning('Forge metadata persistence failed for $forgeId: ${persistedResult.error}');
        return Result.failure(persistedResult.error);
      }

      _log.fine('Downloading Forge libraries for $forgeId');
      final librariesResult = await _installForgeLibraries(
        versionJson: metadata.versionJson,
        installProfile: metadata.installProfile,
        onProgress: onProgress,
      );
      if (librariesResult is Failure<void>) {
        _log.warning('Forge library installation failed for $forgeId: ${librariesResult.error}');
        return Result.failure(librariesResult.error);
      }

      _log.fine('Patching Forge client jar for $forgeId');
      final patchResult = await _patchForgeClientJar(
        minecraftVersion: minecraftVersion,
        forgeId: forgeId,
        installerPath: installerPath,
        tempDir: tempDir,
      );
      if (patchResult is Failure<void>) {
        _log.warning('Forge client patch failed for $forgeId: ${patchResult.error}');
        return Result.failure(patchResult.error);
      }

      final clientJarPath = await _fileService.getClientJarPath(forgeId);
      if (!await File(clientJarPath).exists()) {
        _log.severe('Forge patch completed but client jar was not created: $clientJarPath');
        return Result.failure(
          Exception('Forge client jar was not created: $clientJarPath'),
        );
      }

      _log.info('Forge installation completed successfully for $forgeId');
      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to install Forge $forgeId: $e');
      return Result.failure(Exception('Failed to install Forge: $e'));
    } finally {
      try {
        if (await tempDir.exists()) {
          _log.fine('Cleaning up Forge temp directory ${tempDir.path}');
          await tempDir.delete(recursive: true);
        }
      } catch (_) {
        // Ignore cleanup errors.
      }
    }
  }

  Future<Result<void>> _downloadInstaller({
    required String minecraftVersion,
    required String forgeVersion,
    required String destinationPath,
    void Function(int, int?)? onProgress,
  }) async {
    HttpClient? client;
    try {
      final installerUrl = _apiClient.getInstallerDownloadUrl(
        minecraftVersion,
        forgeVersion,
      );
      _log.finer('Downloading Forge installer from $installerUrl');
      client = HttpClient();
      final request = await client.getUrl(Uri.parse(installerUrl));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log.warning(
          'Forge installer HTTP error for $minecraftVersion-$forgeVersion: ${response.statusCode}',
        );
        return Result.failure(
          Exception(
            'Failed to download Forge installer: HTTP ${response.statusCode}',
          ),
        );
      }

      final file = File(destinationPath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      var downloaded = 0;
      final total = response.contentLength > 0 ? response.contentLength : null;

      await for (final chunk in response) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress?.call(downloaded, total);
      }

      await sink.close();
      _log.fine('Forge installer saved to $destinationPath');
      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to download Forge installer for $minecraftVersion-$forgeVersion: $e');
      return Result.failure(Exception('Failed to download Forge installer: $e'));
    } finally {
      client?.close(force: true);
    }
  }

  Future<Result<void>> _persistForgeMetadata({
    required String forgeId,
    required Map<String, dynamic> installProfile,
    required Map<String, dynamic> versionJson,
  }) async {
    _log.fine('Persisting Forge metadata for $forgeId');
    final versionsDir = await _fileService.getAbsolutePath(['versions', forgeId]);
    await Directory(versionsDir).create(recursive: true);

    final installProfileFile = File(
      p.join(versionsDir, 'install_profile.json'),
    );
    final versionJsonFile = File(p.join(versionsDir, '$forgeId.json'));

    await installProfileFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(installProfile),
    );
    await versionJsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(versionJson),
    );

    _log.fine('Forge metadata written to $versionsDir');
    return const Result.success(null);
  }

  Future<Result<void>> _installForgeLibraries({
    required Map<String, dynamic> versionJson,
    Map<String, dynamic>? installProfile,
    void Function(int, int?)? onProgress,
  }) async {
    try {
      _log.fine('Building Forge library download list');
      final allLibraries = <DownloadModel>[];

      final versionLibs = _extractLibraries(versionJson)
          .where((lib) => lib.url.isNotEmpty && lib.path.isNotEmpty)
          .map(
            (lib) => DownloadModel(
              url: lib.url,
              path: 'libraries/${lib.path}',
              sha1: lib.sha1,
              expectedSize: lib.size,
            ),
          );
      allLibraries.addAll(versionLibs);

      if (installProfile != null && installProfile.containsKey('libraries')) {
        final profileLibs = _extractLibraries(installProfile)
            .where((lib) => lib.url.isNotEmpty && lib.path.isNotEmpty)
            .map(
              (lib) => DownloadModel(
                url: lib.url,
                path: 'libraries/${lib.path}',
                sha1: lib.sha1,
                expectedSize: lib.size,
              ),
            );
        allLibraries.addAll(profileLibs);
      }

      final uniquePaths = <String>{};
      final librariesToDownload = <DownloadModel>[];
      for (final lib in allLibraries) {
        if (uniquePaths.add(lib.path)) {
          librariesToDownload.add(lib);
        }
      }

      if (librariesToDownload.isEmpty) {
        _log.fine('No Forge libraries need to be downloaded');
        return const Result.success(null);
      }

      _log.fine('Downloading ${librariesToDownload.length} Forge libraries');
      final downloadResult = await downloadService.downloadAll(
        librariesToDownload,
        onProgress: onProgress,
      );
      if (downloadResult is Failure<void>) {
        _log.warning('Forge library download batch failed: ${downloadResult.error}');
        return Result.failure(downloadResult.error);
      }

      _log.fine('Forge libraries downloaded successfully');
      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to install Forge libraries: $e');
      return Result.failure(Exception('Failed to install Forge libraries: $e'));
    }
  }

  Future<Result<void>> _extractForgeInstaller({
    required String installerPath,
    required String forgeId,
  }) async {
    try {
      _log.fine('Extracting Forge installer archive from $installerPath');
      final installerFile = File(installerPath);
      if (!await installerFile.exists()) {
        _log.warning('Forge installer archive missing at $installerPath');
        return Result.failure(
          Exception('Forge installer not found: $installerPath'),
        );
      }

      final archive = ZipDecoder().decodeBytes(await installerFile.readAsBytes());

      final installProfileBytes = _readArchiveFile(archive, 'install_profile.json');
      if (installProfileBytes == null) {
        _log.warning('install_profile.json not found inside Forge installer $installerPath');
        return Result.failure(
          Exception('install_profile.json not found inside Forge installer'),
        );
      }
      final installProfile = jsonDecode(utf8.decode(installProfileBytes)) as Map<String, dynamic>;

      Map<String, dynamic>? versionJson;
      final versionJsonBytes = _readArchiveFile(archive, 'version.json');
      if (versionJsonBytes != null) {
        versionJson = jsonDecode(utf8.decode(versionJsonBytes)) as Map<String, dynamic>;
      } else if (installProfile.containsKey('versionInfo')) {
        versionJson = installProfile['versionInfo'] as Map<String, dynamic>;
      } else {
        _log.warning('version.json not found inside Forge installer $installerPath');
        return Result.failure(
          Exception('version.json not found inside Forge installer'),
        );
      }
      
      final installBlock = installProfile['install'] as Map<String, dynamic>?;
      if (installBlock != null) {
        final filePath = installBlock['filePath'] as String?;
        final path = installBlock['path'] as String?;
        if (filePath != null && path != null) {
          final libraryPath = await _fileService.getAbsolutePath(['libraries', _mavenToPath(path)]);
          _extractFromInstaller(installerPath, filePath, libraryPath);
        }
      }

      _metadataCache[forgeId] = _ForgeInstallerMetadata(
        installProfile: installProfile,
        versionJson: versionJson,
      );
      _log.fine('Cached Forge installer metadata for $forgeId');

      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to extract Forge installer for $forgeId: $e');
      return Result.failure(Exception('Failed to process Forge installation: $e'));
    }
  }

  Future<Result<void>> _patchForgeClientJar({
    required String minecraftVersion,
    required String forgeId,
    required String installerPath,
    required Directory tempDir,
  }) async {
    try {
      final metadata = _metadataCache[forgeId];
      if (metadata == null) {
        return Result.failure(Exception('Metadata not found for $forgeId'));
      }

      final targetJarPath = await _fileService.getClientJarPath(forgeId);
      final processors = metadata.installProfile['processors'] as List<dynamic>?;

      if (processors == null || processors.isEmpty) {
        final sourceJarPath = await _fileService.getClientJarPath(minecraftVersion);
        _log.fine('Copying Minecraft client jar from $sourceJarPath to $targetJarPath');

        final sourceFile = File(sourceJarPath);
        if (!await sourceFile.exists()) {
          _log.warning('Vanilla Minecraft client jar missing for $minecraftVersion');
          return Result.failure(
            Exception('Vanilla Minecraft client jar not found: $sourceJarPath'),
          );
        }

        final targetFile = File(targetJarPath);
        await targetFile.parent.create(recursive: true);
        await sourceFile.copy(targetJarPath);

        _log.fine('Forge client jar patched at $targetJarPath');
        return const Result.success(null);
      }

      final data = metadata.installProfile['data'] as Map<String, dynamic>? ?? {};
      final librariesDir = await _fileService.getAbsolutePath(['libraries']);
      final vanillaJarPath = await _fileService.getClientJarPath(minecraftVersion);

      if (!await File(vanillaJarPath).exists()) {
        return Result.failure(Exception('Vanilla Minecraft client jar not found: $vanillaJarPath'));
      }

      String resolveVar(String value) {
        if (value.startsWith('[') && value.endsWith(']')) {
          final coord = value.substring(1, value.length - 1);
          return p.join(librariesDir, _mavenToPath(coord));
        } else if (value.startsWith('/')) {
          final relativePath = value.substring(1);
          final extractedPath = p.join(tempDir.path, relativePath.replaceAll('/', Platform.pathSeparator));
          if (!File(extractedPath).existsSync()) {
            _extractFromInstaller(installerPath, relativePath, extractedPath);
          }
          return extractedPath;
        }
        return value;
      }

      for (final proc in processors) {
        final procMap = proc as Map<String, dynamic>;
        final sides = procMap['sides'] as List<dynamic>?;
        if (sides != null && !sides.contains('client')) {
          continue;
        }

        final jarCoord = procMap['jar'] as String;
        final jarPath = p.join(librariesDir, _mavenToPath(jarCoord));

        final cpCoords = procMap['classpath'] as List<dynamic>? ?? [];
        final cpPaths = cpCoords.map((c) => p.join(librariesDir, _mavenToPath(c as String))).toList();

        final args = procMap['args'] as List<dynamic>? ?? [];
        final resolvedArgs = <String>[];

        for (var arg in args) {
          arg = arg as String;
          arg = arg.replaceAllMapped(RegExp(r'\{([A-Z_]+)\}'), (match) {
            final name = match.group(1)!;
            if (name == 'MINECRAFT_JAR') return vanillaJarPath;
            if (name == 'MINECRAFT_VERSION') return minecraftVersion;
            if (name == 'INSTALLER') return installerPath;
            if (name == 'LIBRARY_DIR') return librariesDir;
            if (name == 'SIDE') return 'client';
            if (name == 'ROOT') return librariesDir;

            if (data.containsKey(name)) {
              final dataObj = data[name];
              if (dataObj is Map<String, dynamic>) {
                final dataValue = dataObj['client'] as String?;
                if (dataValue != null) return resolveVar(dataValue);
              } else if (dataObj is String) {
                return resolveVar(dataObj);
              }
            }
            return match.group(0)!;
          });

          resolvedArgs.add(resolveVar(arg));
        }

        final outputs = procMap['outputs'] as Map<String, dynamic>?;
        if (outputs != null) {
          for (final key in outputs.keys) {
            final resolvedOutput = resolveVar(key.replaceAllMapped(RegExp(r'\{([A-Z_]+)\}'), (match) {
              final name = match.group(1)!;
              if (data.containsKey(name)) {
                final dataObj = data[name];
                if (dataObj is Map<String, dynamic>) {
                  final dataValue = dataObj['client'] as String?;
                  if (dataValue != null) return resolveVar(dataValue);
                } else if (dataObj is String) {
                  return resolveVar(dataObj);
                }
              }
              return match.group(0)!;
            }));
            await File(resolvedOutput).parent.create(recursive: true);
          }
        }

        final mainClass = await _getMainClassFromJar(jarPath);
        if (mainClass == null) {
          return Result.failure(Exception('Main-Class not found in $jarPath'));
        }

        final cpString = [jarPath, ...cpPaths].join(Platform.isWindows ? ';' : ':');

        _log.fine('Running Forge processor: $jarCoord');
        final javaResult = await Process.run('java', [
          '-cp',
          cpString,
          mainClass,
          ...resolvedArgs,
        ]);

        if (javaResult.exitCode != 0) {
          _log.severe('Processor failed: \\nStdout: ${javaResult.stdout}\\nStderr: ${javaResult.stderr}');
          return Result.failure(Exception('Processor failed: ${javaResult.stderr}'));
        }
      }

      final patchedObj = data['PATCHED'];
      if (patchedObj != null) {
        String? patchedVal;
        if (patchedObj is Map<String, dynamic>) {
          patchedVal = patchedObj['client'] as String?;
        } else if (patchedObj is String) {
          patchedVal = patchedObj;
        }

        if (patchedVal != null) {
          final patchedJarPath = resolveVar(patchedVal);
          if (await File(patchedJarPath).exists()) {
            await File(targetJarPath).parent.create(recursive: true);
            await File(patchedJarPath).copy(targetJarPath);
            _log.fine('Forge client jar patched and copied to $targetJarPath');
          } else {
            return Result.failure(Exception('Patched jar not found at $patchedJarPath after processing'));
          }
        }
      } else {
         // If there is no PATCHED, maybe we should copy the vanilla jar to targetJarPath
         await File(vanillaJarPath).copy(targetJarPath);
      }

      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to patch Forge client jar for $forgeId: $e');
      return Result.failure(Exception('Failed to patch Forge client jar: $e'));
    }
  }

  String _mavenToPath(String coord) {
    var ext = 'jar';
    if (coord.contains('@')) {
      final parts = coord.split('@');
      coord = parts[0];
      ext = parts[1];
    }
    final parts = coord.split(':');
    final groupId = parts[0];
    final artifactId = parts[1];
    final version = parts[2];
    String? classifier;
    if (parts.length > 3) {
      classifier = parts[3];
    }

    final groupPath = groupId.replaceAll('.', '/');
    final classifierPart = classifier != null ? '-$classifier' : '';
    return '$groupPath/$artifactId/$version/$artifactId-$version$classifierPart.$ext';
  }

  void _extractFromInstaller(String installerPath, String relativePath, String targetPath) {
    final bytes = File(installerPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.findFile(relativePath);
    if (file != null) {
      File(targetPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);
    } else {
      throw Exception('File $relativePath not found in installer $installerPath');
    }
  }

  Future<String?> _getMainClassFromJar(String jarPath) async {
    try {
      final bytes = await File(jarPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      ArchiveFile? mf;
      for (final file in archive) {
        if (file.name.toUpperCase() == 'META-INF/MANIFEST.MF') {
          mf = file;
          break;
        }
      }

      if (mf != null) {
        final content = utf8.decode(mf.content as List<int>, allowMalformed: true);
        for (final line in content.split('\n')) {
          if (line.trimLeft().toLowerCase().startsWith('main-class:')) {
            return line.trimLeft().substring('main-class:'.length).trim();
          }
        }
        _log.warning('Main-Class not found in manifest of $jarPath. Content: $content');
      } else {
        _log.warning('META-INF/MANIFEST.MF not found in $jarPath. Files: ${archive.files.take(10).map((f) => f.name).join(', ')}...');
      }
    } catch (e) {
      _log.severe('Error reading main class from $jarPath: $e');
    }
    return null;
  }

  List<int>? _readArchiveFile(Archive archive, String fileName) {
    for (final file in archive) {
      if (file.isFile && file.name.endsWith(fileName)) {
        return file.content as List<int>;
      }
    }
    return null;
  }

  List<ForgeLibraryEntry> _extractLibraries(Map<String, dynamic> versionJson) {
    final libraries = versionJson['libraries'] as List<dynamic>? ?? const [];
    return libraries
        .map((library) => library as Map<String, dynamic>)
        .map((lib) {
          final name = lib['name'] as String?;
          final downloads = lib['downloads'] as Map<String, dynamic>?;
          final artifact = downloads?['artifact'] as Map<String, dynamic>?;
          
          String path = artifact?['path'] as String? ?? '';
          if (path.isEmpty && name != null) {
            path = _mavenToPath(name);
          }
          
          String url = artifact?['url'] as String? ?? '';
          if (url.isEmpty && path.isNotEmpty) {
            final baseUrl = lib['url'] as String?;
            if (baseUrl != null) {
              url = baseUrl.endsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
            } else {
              url = 'https://libraries.minecraft.net/$path';
            }
          }

          return ForgeLibraryEntry(
            path: path,
            url: url,
            sha1: artifact?['sha1'] as String? ?? '',
            size: artifact?['size'] as int?,
          );
        })
        .toList();
  }

  List<String> _extractLibraryPaths(Map<String, dynamic> versionJson) {
    return _extractLibraries(versionJson)
        .map((entry) => entry.path)
        .where((path) => path.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>?> _readVersionJson(String forgeId) async {
    final cached = _metadataCache[forgeId];
    if (cached != null) {
      _log.finer('Using cached Forge version JSON for $forgeId');
      return cached.versionJson;
    }

    final file = await _forgeVersionJsonFile(forgeId);
    if (!await file.exists()) {
      _log.finer('Forge version JSON not found at ${file.path}');
      return null;
    }

    _log.finer('Reading Forge version JSON from ${file.path}');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<File> _forgeVersionJsonFile(String forgeId) async {
    final versionsDir = await _fileService.getAbsolutePath(['versions', forgeId]);
    return File(p.join(versionsDir, '$forgeId.json'));
  }

  Future<String?> _resolveInstalledForgeId(String id) async {
    final normalized = _normalizeForgeVersion(id);
    if (normalized.contains('-forge-')) {
      _log.finer('Forge id already resolved: $normalized');
      return normalized;
    }

    for (final forgeId in _metadataCache.keys) {
      if (forgeId.endsWith('-forge-$normalized')) {
        _log.finer('Resolved Forge id from cache: $forgeId');
        return forgeId;
      }
    }

    final versionsDirPath = await _fileService.getAbsolutePath(['versions']);
    final versionsDir = Directory(versionsDirPath);
    if (!await versionsDir.exists()) {
      _log.finer('Versions directory missing while resolving Forge id for $id');
      return null;
    }

    await for (final entity in versionsDir.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }

      final forgeId = p.basename(entity.path);
      if (!forgeId.endsWith('-forge-$normalized')) {
        continue;
      }

      final versionJsonFile = File(p.join(entity.path, '$forgeId.json'));
      if (await versionJsonFile.exists()) {
        _log.finer('Resolved Forge id from disk: $forgeId');
        return forgeId;
      }
    }

    return null;
  }

  ({String minecraftVersion, String forgeVersion})? _parseInstallTarget(
    String id,
    String? minecraftVersion,
  ) {
    final normalized = _normalizeForgeVersion(id);
    final splitIndex = normalized.indexOf('-forge-');
    if (splitIndex != -1) {
      return (
        minecraftVersion: normalized.substring(0, splitIndex),
        forgeVersion: normalized.substring(splitIndex + '-forge-'.length),
      );
    }

    if (minecraftVersion == null || minecraftVersion.isEmpty) {
      return null;
    }

    return (
      minecraftVersion: minecraftVersion,
      forgeVersion: normalized,
    );
  }

  String _forgeId(String minecraftVersion, String forgeVersion) {
    return '$minecraftVersion-forge-$forgeVersion';
  }

  String _normalizeForgeVersion(String id) {
    return id.startsWith('forge-') ? id.substring('forge-'.length) : id;
  }
}

class _ForgeInstallerMetadata {
  final Map<String, dynamic> installProfile;
  final Map<String, dynamic> versionJson;

  const _ForgeInstallerMetadata({
    required this.installProfile,
    required this.versionJson,
  });
}

class ForgeLibraryEntry {
  final String path;
  final String url;
  final String sha1;
  final int? size;

  ForgeLibraryEntry({
    required this.path,
    required this.url,
    required this.sha1,
    required this.size,
  });
}
