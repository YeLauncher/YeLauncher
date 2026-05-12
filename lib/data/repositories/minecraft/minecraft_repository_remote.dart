import 'dart:io';

import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/models/library_api_model.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_manifest_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/local/file_service.dart';
import 'package:yelauncher/data/services/local/minecraft_service.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_run_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/models/download_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_file_api_model.dart';

class MinecraftRepositoryRemote implements MinecraftRepository {
  final MinecraftApiClient _apiClient;
  final MinecraftService _minecraftService;
  final DownloadService _downloadService;
  final FileService _fileService;

  MinecraftRepositoryRemote({
    required MinecraftApiClient apiClient,
    required MinecraftService minecraftService,
    required DownloadService downloadService,
    required FileService fileService,
  }) : _apiClient = apiClient,
       _minecraftService = minecraftService,
       _downloadService = downloadService,
       _fileService = fileService;

  @override
  Future<Result<List<MinecraftVersionModel>>> getVersions() async {
    try {
      final result = await _apiClient.getManifest();
      switch (result) {
        case Success<VersionManifestApiModel>():
          final versions = result.value.versions.map((apiModel) {
            return MinecraftVersionModel(
              id: apiModel.id,
              type: apiModel.type,
              releaseTime: apiModel.releaseTime,
            );
          }).toList();
          return Result.success(versions);
        case Failure<VersionManifestApiModel>():
          return Result.failure(result.error);
      }
    } on Exception catch (error) {
      return Result.failure(error);
    }
  }

  @override
  Future<Result<void>> install(String id) async {
    var versionResult = await _apiClient.getVersion(id);
    switch (versionResult) {
      case Success<VersionApiModel>():
        var requirementsResult = await _apiClient.getRequirements(
          versionResult.value,
        );
        switch (requirementsResult) {
          case Success<VersionRequirementsApiModel>():
            var requirements = requirementsResult.value;

            final downloads = <DownloadModel>[];

            // 1. Client
            downloads.add(
              DownloadModel(
                url: requirements.client.url,
                path: 'versions/$id/$id.jar',
                sha1: requirements.client.sha1,
                expectedSize: requirements.client.size,
                tag: id,
              ),
            );

            // 2. Libraries
            for (final lib in requirements.libraries) {
              if (lib.url.isEmpty) continue;
              downloads.add(
                DownloadModel(
                  url: lib.url,
                  path: 'libraries/${lib.path}',
                  sha1: lib.sha1,
                  expectedSize: lib.size,
                  tag: id,
                ),
              );
            }

            // 3. Asset Index
            final assetIndex = requirements.assetIndex;
            downloads.add(
              DownloadModel(
                url: assetIndex.url,
                path: 'assets/indexes/${assetIndex.id}.json',
                sha1: assetIndex.sha1,
                expectedSize: assetIndex.size,
                tag: id,
              ),
            );

            final initialDownloadsResult = await _downloadService.downloadAll(
              downloads,
            );
            if (initialDownloadsResult is Failure<void>) {
              _downloadService.clearTrackedModels(id);
              return initialDownloadsResult;
            }

            // 4. Download Assets
            final assetDownloads = <DownloadModel>[];
            final indexResult = await _apiClient.getAssetIndex(assetIndex.url);
            switch (indexResult) {
              case Success<AssetIndexFileApiModel>():
                final objects = indexResult.value.objects;
                for (final entry in objects.entries) {
                  final hash = entry.value.hash;
                  final size = entry.value.size;
                  final prefix = hash.substring(0, 2);
                  assetDownloads.add(
                    DownloadModel(
                      url:
                          'https://resources.download.minecraft.net/$prefix/$hash',
                      path: 'assets/objects/$prefix/$hash',
                      sha1: hash,
                      expectedSize: size,
                      tag: id,
                    ),
                  );
                }

                final assetDownloadsResult = await _downloadService.downloadAll(
                  assetDownloads,
                );
                if (assetDownloadsResult is Failure<void>) {
                  _downloadService.clearTrackedModels(id);
                  return assetDownloadsResult;
                }
              case Failure<AssetIndexFileApiModel>():
                _downloadService.clearTrackedModels(id);
                return Result.failure(indexResult.error);
            }

            _downloadService.clearTrackedModels(id);
            return const Result.success(null);
          case Failure<VersionRequirementsApiModel>():
            return Result.failure(requirementsResult.error);
        }
      case Failure<VersionApiModel>():
        return Result.failure(versionResult.error);
    }
  }

  @override
  Future<Result<bool>> isInstalled(String id) {
    // TODO: implement isInstalled
    throw UnimplementedError();
  }

  @override
  Future<Result<String>> getJavaVersion(String id) async {
    var versionResult = await _apiClient.getVersion(id);
    switch (versionResult) {
      case Success<VersionApiModel>():
        var requirementsResult = await _apiClient.getRequirements(
          versionResult.value,
        );
        switch (requirementsResult) {
          case Success<VersionRequirementsApiModel>():
            return Result.success(requirementsResult.value.javaVersion);
          case Failure<VersionRequirementsApiModel>():
            return Result.failure(requirementsResult.error);
        }
      case Failure<VersionApiModel>():
        return Result.failure(versionResult.error);
    }
  }

  @override
  Future<Result<void>> run(String id) async {
    try {
      final versionResult = await _apiClient.getVersion(id);
      switch (versionResult) {
        case Success<VersionApiModel>():
          final requirementsResult = await _apiClient.getRequirements(
            versionResult.value,
          );
          switch (requirementsResult) {
            case Success<VersionRequirementsApiModel>():
              var requirements = requirementsResult.value;

              final List<String> libraryPaths = [];
              final List<String> nativeLibraryPaths = [];

              for (final lib in requirements.libraries) {
                if (!_isAllowed(lib.rules)) continue;
                if (lib.isNative) {
                  nativeLibraryPaths.add(await _getNativeLibraryPath(lib));
                  continue;
                }
                libraryPaths.add(await _getLibraryPath(lib));
              }

              var model = MinecraftRunModel(
                libraryPaths: libraryPaths,
                nativeLibraryPaths: nativeLibraryPaths,
                jvmArguments: _getJvmArguments(requirements),
                gameArguments: _getGameArguments(requirements),
                mainClass: requirements.mainClass,
                assetsDirectory: await _getAssetDirectory(requirements),
                gameDirectory: await _getGameDirectory(id),
                nativesDirectory: await _getNativesDirectory(id),
                clientJarPath: await _getClientJarPath(id),
                javaExecutablePath: await _getJavaExecutablePath(requirements.javaVersion),
              );
              return _minecraftService.run(model);
            case Failure<VersionRequirementsApiModel>():
              return Result.failure(requirementsResult.error);
          }
        case Failure<VersionApiModel>():
          return Result.failure(versionResult.error);
      }
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  bool _isAllowed(List<RuleApiModel>? rules) {
    if (rules == null || rules.isEmpty) return true;
    bool allowed = false;
    for (final rule in rules) {
      bool osMatch = true;
      if (rule.os != null && rule.os!.name != null) {
        String currentOs = Platform.operatingSystem;
        if (currentOs == 'macos') currentOs = 'osx';
        osMatch = (rule.os!.name == currentOs);
      }
      if (osMatch) {
        allowed = (rule.action == 'allow');
      }
    }
    return allowed;
  }

  Future<String> _getLibraryPath(LibraryApiModel library) async {
  }

  Future<String> _getNativeLibraryPath(LibraryApiModel library) async {
  }
  
  Future<String> _getAssetDirectory(VersionRequirementsApiModel requirements) async {
  }

  Future<String> _getGameDirectory(String id) async {
  }

  Future<String> _getNativesDirectory(String id) async {
  }

  Future<String> _getClientJarPath(String id) async {
  }

  Future<String> _getJavaExecutablePath(String id) async {
  }

  List<String> _getJvmArguments(VersionRequirementsApiModel requirements) {
  }

  List<String> _getGameArguments(VersionRequirementsApiModel requirements) {
  }
}
