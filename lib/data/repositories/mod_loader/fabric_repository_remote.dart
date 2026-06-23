import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/api/fabric_api_client.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/file_service.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class FabricRepositoryRemote implements ModLoaderRepository {
  final _log = Logger('FabricRepositoryRemote');
  final FabricApiClient _apiClient;
  final DownloadService _downloadService;
  final FileService _fileService;

  FabricRepositoryRemote({
    required FabricApiClient apiClient,
    required DownloadService downloadService,
    required FileService fileService,
  })  : _apiClient = apiClient,
        _downloadService = downloadService,
        _fileService = fileService;

  @override
  String get id => 'fabric';

  @override
  String get name => 'Fabric';

  @override
  String get icon => 'assets/fabric.svg';

  @override
  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  ) async {
    try {
      final versions = await _apiClient.getVersions(minecraftVersion);
      final mappedVersions = versions.map((apiModel) {
        return ModLoaderVersionModel(
          id: 'fabric-${apiModel.version}',
          version: apiModel.version,
          type: apiModel.stable ? 'stable' : 'snapshot',
        );
      }).toList();
      return Result.success(mappedVersions);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<String>>> getLibrariesPath(String id) async {
    try {
      _log.fine('Resolving Fabric libraries for $id');
      final fabricId = await _resolveInstalledFabricId(id);
      if (fabricId == null) {
        _log.warning('Fabric libraries lookup failed for $id: no installed version found');
        return Result.failure(
          Exception('Fabric version JSON not found for $id'),
        );
      }

      final versionJson = await _readVersionJson(fabricId);
      if (versionJson == null) {
        _log.warning('Fabric libraries lookup failed for $fabricId: version JSON missing');
        return Result.failure(
          Exception('Fabric version JSON not found for $fabricId'),
        );
      }

      final paths = _extractLibraryPaths(versionJson);
      _log.fine('Resolved ${paths.length} Fabric libraries for $fabricId');
      return Result.success(paths);
    } catch (e) {
      _log.severe('Failed to read Fabric libraries for $id: $e');
      return Result.failure(Exception('Failed to read Fabric libraries: $e'));
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
        _log.warning('Fabric install aborted for $id: minecraftVersion missing');
        return Result.failure(
          Exception('minecraftVersion is required for Fabric installation'),
        );
      }

      _log.info(
        'Installing Fabric for Minecraft ${target.minecraftVersion} using Fabric ${target.fabricVersion}',
      );
      final result = await _installFabric(
        minecraftVersion: target.minecraftVersion,
        fabricVersion: target.fabricVersion,
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
      _log.fine('Checking Fabric installation status for $id');
      final fabricId = await _resolveInstalledFabricId(id);
      if (fabricId == null) {
        _log.fine('Fabric installation not found for $id');
        return const Result.success(false);
      }

      final versionJson = await _readVersionJson(fabricId);
      if (versionJson == null) {
        _log.fine('Fabric version JSON missing for $fabricId');
        return const Result.success(false);
      }

      final libraryPaths = _extractLibraryPaths(versionJson);
      for (final libPath in libraryPaths) {
        final fullPath = await _fileService.getLibraryPath(libPath);
        if (!await File(fullPath).exists()) {
          _log.fine('Fabric installation check for $fabricId: library $libPath is missing');
          return const Result.success(false);
        }
      }

      _log.fine('Fabric installation check for $fabricId: all files exist');
      return const Result.success(true);
    } catch (e) {
      _log.warning('Failed to check Fabric installation for $id: $e');
      return Result.failure(Exception('Failed to check Fabric installation: $e'));
    }
  }

  @override
  Future<Result<void>> processInstallation(
    String id,
    String minecraftVersion,
  ) async {
    try {
      _log.info('Processing Fabric installation for $id and Minecraft $minecraftVersion');
      final target = _parseInstallTarget(id, minecraftVersion);
      if (target == null) {
        _log.warning('Fabric processInstallation aborted for $id: minecraftVersion missing');
        return Result.failure(
          Exception('minecraftVersion is required for Fabric installation'),
        );
      }

      return _installFabric(
        minecraftVersion: target.minecraftVersion,
        fabricVersion: target.fabricVersion,
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<void>> _installFabric({
    required String minecraftVersion,
    required String fabricVersion,
    void Function(int, int?)? onProgress,
  }) async {
    final fabricId = _fabricId(minecraftVersion, fabricVersion);
    try {
      _log.info('Starting Fabric install for $fabricId');

      _log.fine('Fetching Fabric profile JSON for $fabricId');
      final versionJson = await _apiClient.getProfileJson(minecraftVersion, fabricVersion);

      _log.fine('Persisting Fabric metadata for $fabricId');
      final persistedResult = await _persistFabricMetadata(
        fabricId: fabricId,
        versionJson: versionJson,
      );
      if (persistedResult is Failure<void>) {
        _log.warning('Fabric metadata persistence failed for $fabricId: ${persistedResult.error}');
        return Result.failure(persistedResult.error);
      }

      _log.fine('Downloading Fabric libraries for $fabricId');
      final librariesResult = await _installFabricLibraries(
        versionJson: versionJson,
        onProgress: onProgress,
      );
      if (librariesResult is Failure<void>) {
        _log.warning('Fabric library installation failed for $fabricId: ${librariesResult.error}');
        return Result.failure(librariesResult.error);
      }

      _log.info('Fabric installation completed successfully for $fabricId');
      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to install Fabric $fabricId: $e');
      return Result.failure(Exception('Failed to install Fabric: $e'));
    }
  }

  Future<Result<void>> _persistFabricMetadata({
    required String fabricId,
    required Map<String, dynamic> versionJson,
  }) async {
    _log.fine('Persisting Fabric metadata for $fabricId');
    final versionsDir = await _fileService.getAbsolutePath(['versions', fabricId]);
    await Directory(versionsDir).create(recursive: true);

    final versionJsonFile = File(p.join(versionsDir, '$fabricId.json'));

    await versionJsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(versionJson),
    );

    _log.fine('Fabric metadata written to $versionsDir');
    return const Result.success(null);
  }

  Future<Result<void>> _installFabricLibraries({
    required Map<String, dynamic> versionJson,
    void Function(int, int?)? onProgress,
  }) async {
    try {
      _log.fine('Building Fabric library download list');
      final librariesToDownload = <DownloadModel>[];

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
      librariesToDownload.addAll(versionLibs);

      if (librariesToDownload.isEmpty) {
        _log.fine('No Fabric libraries need to be downloaded');
        return const Result.success(null);
      }

      _log.fine('Downloading ${librariesToDownload.length} Fabric libraries');
      final downloadResult = await _downloadService.downloadAll(
        librariesToDownload,
        onProgress: onProgress,
      );
      if (downloadResult is Failure<void>) {
        _log.warning('Fabric library download batch failed: ${downloadResult.error}');
        return Result.failure(downloadResult.error);
      }

      _log.fine('Fabric libraries downloaded successfully');
      return const Result.success(null);
    } catch (e) {
      _log.severe('Failed to install Fabric libraries: $e');
      return Result.failure(Exception('Failed to install Fabric libraries: $e'));
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

  List<_FabricLibraryEntry> _extractLibraries(Map<String, dynamic> versionJson) {
    final libraries = versionJson['libraries'] as List<dynamic>? ?? const [];
    return libraries
        .map((library) => library as Map<String, dynamic>)
        .map((lib) {
          final name = lib['name'] as String?;
          String path = '';
          if (name != null) {
            path = _mavenToPath(name);
          }
          
          String url = lib['url'] as String? ?? 'https://maven.fabricmc.net/';
          if (!url.endsWith('/')) {
            url += '/';
          }
          url += path;

          return _FabricLibraryEntry(
            path: path,
            url: url,
            sha1: lib['sha1'] as String? ?? '',
            size: lib['size'] as int?,
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

  Future<Map<String, dynamic>?> _readVersionJson(String fabricId) async {
    final versionsDir = await _fileService.getAbsolutePath(['versions', fabricId]);
    final file = File(p.join(versionsDir, '$fabricId.json'));
    
    if (!await file.exists()) {
      _log.finer('Fabric version JSON not found at ${file.path}');
      return null;
    }

    _log.finer('Reading Fabric version JSON from ${file.path}');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<String?> _resolveInstalledFabricId(String id) async {
    final normalized = _normalizeFabricVersion(id);
    if (normalized.contains('-fabric-')) {
      _log.finer('Fabric id already resolved: $normalized');
      return normalized;
    }

    final versionsDirPath = await _fileService.getAbsolutePath(['versions']);
    final versionsDir = Directory(versionsDirPath);
    if (!await versionsDir.exists()) {
      _log.finer('Versions directory missing while resolving Fabric id for $id');
      return null;
    }

    await for (final entity in versionsDir.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }

      final fabricId = p.basename(entity.path);
      if (!fabricId.endsWith('-fabric-$normalized')) {
        continue;
      }

      final versionJsonFile = File(p.join(entity.path, '$fabricId.json'));
      if (await versionJsonFile.exists()) {
        _log.finer('Resolved Fabric id from disk: $fabricId');
        return fabricId;
      }
    }

    return null;
  }

  ({String minecraftVersion, String fabricVersion})? _parseInstallTarget(
    String id,
    String? minecraftVersion,
  ) {
    final normalized = _normalizeFabricVersion(id);
    final splitIndex = normalized.indexOf('-fabric-');
    if (splitIndex != -1) {
      return (
        minecraftVersion: normalized.substring(0, splitIndex),
        fabricVersion: normalized.substring(splitIndex + '-fabric-'.length),
      );
    }

    if (minecraftVersion == null || minecraftVersion.isEmpty) {
      return null;
    }

    return (
      minecraftVersion: minecraftVersion,
      fabricVersion: normalized,
    );
  }

  String _fabricId(String minecraftVersion, String fabricVersion) {
    return '$minecraftVersion-fabric-$fabricVersion';
  }

  String _normalizeFabricVersion(String id) {
    return id.startsWith('fabric-') ? id.substring('fabric-'.length) : id;
  }
}

class _FabricLibraryEntry {
  final String path;
  final String url;
  final String sha1;
  final int? size;

  const _FabricLibraryEntry({
    required this.path,
    required this.url,
    required this.sha1,
    this.size,
  });
}
