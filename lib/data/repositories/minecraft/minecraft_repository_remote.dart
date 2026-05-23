import 'dart:ffi';
import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'package:logging/logging.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/microsoft_api_client.dart';
import 'package:yelauncher/data/services/api/models/minecraft_profile_api_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_file_api_model.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_manifest_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/file_service.dart';
import 'package:yelauncher/data/services/minecraft_service.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_run_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class MinecraftRepositoryRemote implements MinecraftRepository {
  final _log = Logger('MinecraftRepositoryRemote');
  final MinecraftApiClient _apiClient;
  final MinecraftService _minecraftService;
  final DownloadService _downloadService;
  final FileService _fileService;
  final JavaRepository _javaRepository;
  final SecureStorageService _secureStorage;

  MinecraftRepositoryRemote({
    required MinecraftApiClient apiClient,
    required MinecraftService minecraftService,
    required DownloadService downloadService,
    required FileService fileService,
    required JavaRepository javaRepository,
    required SecureStorageService secureStorage,
  }) : _apiClient = apiClient,
       _minecraftService = minecraftService,
       _downloadService = downloadService,
       _fileService = fileService,
       _javaRepository = javaRepository,
       _secureStorage = secureStorage;

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
  Future<Result<void>> install(
    String id, {
    void Function(int, int?)? onProgress,
  }) async {
    var versionResult = await _apiClient.getVersion(id);
    final result = await versionResult
        .flatMapAsync((version) => _apiClient.getRequirements(version))
        .foldAsync((requirements) async {
          // 1. Download Asset Index
          final assetIndex = requirements.assetIndex;
          final indexDownload = DownloadModel(
            url: assetIndex.url,
            path: 'assets/indexes/${assetIndex.id}.json',
            sha1: assetIndex.sha1,
            expectedSize: assetIndex.size,
          );

          final indexDownloadResult = await _downloadService.downloadAll([
            indexDownload,
          ]);
          if (indexDownloadResult is Failure<void>) {
            return indexDownloadResult;
          }

          // 2. Download Assets, Client, and Libraries
          final indexResult = await _apiClient.getAssetIndex(
            requirements.assetIndex.url,
          );
          switch (indexResult) {
            case Success<AssetIndexFileApiModel>():
              final downloads = <DownloadModel>[];

              // Client
              downloads.add(
                DownloadModel(
                  url: requirements.client.url,
                  path: 'versions/$id/$id.jar',
                  sha1: requirements.client.sha1,
                  expectedSize: requirements.client.size,
                ),
              );

              // Libraries
              for (final lib in requirements.libraries) {
                if (lib.url.isEmpty) continue;
                downloads.add(
                  DownloadModel(
                    url: lib.url,
                    path: 'libraries/${lib.path}',
                    sha1: lib.sha1,
                    expectedSize: lib.size,
                  ),
                );
              }

              // Assets
              downloads.addAll(_createAssetDownloads(id, indexResult.value));

              final downloadsResult = await _downloadService.downloadAll(
                downloads,
                onProgress: onProgress,
              );

              if (downloadsResult is Failure<void>) {
                return downloadsResult;
              }
            case Failure<AssetIndexFileApiModel>():
              return Result.failure(indexResult.error);
          }

          return const Result.success(null);
        }, (error) async => Result.failure(error));

    return result;
  }

  @override
  Future<Result<bool>> isInstalled(String id) async {
    // 1. Fast path: Check if the main client jar exists first.
    // If it doesn't, we immediately know it's not installed.
    final clientJarPath = await _fileService.getClientJarPath(id);
    if (!await File(clientJarPath).exists()) {
      return const Result.success(false);
    }

    // 2. Slow path: Check if the required assets for this version exist.
    final versionResult = await _apiClient.getVersion(id);
    return versionResult
        .flatMapAsync((version) => _apiClient.getRequirements(version))
        .foldAsync((requirements) async {
          // Check if the specific asset index file for this version exists
          final assetIndexId = requirements.assetIndex.id;
          final indexPath = await _fileService.getAbsolutePath([
            'assets',
            'indexes',
            '$assetIndexId.json',
          ]);

          final indexExists = await File(indexPath).exists();
          return Result.success(indexExists);
        }, (error) async => Result.failure(error));
  }

  @override
  Future<Result<String>> getJavaVersion(String id) async {
    var versionResult = await _apiClient.getVersion(id);
    return versionResult
        .flatMapAsync((version) => _apiClient.getRequirements(version))
        .map((requirements) => requirements.javaVersion);
  }

  @override
  Future<Result<void>> run(String id) async {
    try {
      final versionResult = await _apiClient.getVersion(id);
      return versionResult
          .flatMapAsync((version) => _apiClient.getRequirements(version))
          .foldAsync((requirements) async {
            final List<String> libraryPaths = [];
            final List<String> nativeLibraryPaths = [];

            for (final lib in requirements.libraries) {
              if (!_isAllowed(lib.rules)) continue;
              if (lib.isNative) {
                await _fileService.extractNatives(
                  await _fileService.getLibraryPath(lib.path),
                  await _fileService.getNativesDirectory(id),
                );
              }
              libraryPaths.add(await _fileService.getLibraryPath(lib.path));
            }

            var model = MinecraftRunModel(
              libraryDirectory: await _fileService.getLibraryDirectory(),
              libraryPaths: libraryPaths,
              nativeLibraryPaths: nativeLibraryPaths,
              jvmArguments: _getJvmArguments(requirements),
              gameArguments: _getGameArguments(requirements),
              mainClass: requirements.mainClass,
              assetsDirectory: await _fileService.getAssetDirectory(),
              gameDirectory: await _fileService.getGameDirectory(id),
              nativesDirectory: await _fileService.getNativesDirectory(id),
              clientJarPath: await _fileService.getClientJarPath(id),
              javaExecutablePath: await _getJavaExecutablePathAbs(
                int.tryParse(requirements.javaVersion) ?? 17,
              ),
              assetIndex: requirements.assetIndex.id,
              minecraftVersion: requirements.id,
              profile: MinecraftProfileModel(
                nickname: "Xemii16",
                uuid: "1fd9c8be-50cb-49c3-a755-b29dc8483184",
                accessToken: "test",
                userType: "offline",
              ),
            );
            return _minecraftService.run(model);
          }, (error) async => Result.failure(error));
    } on Exception catch (e) {
      _log.severe('Exception while trying to run Minecraft version $id: $e');
      return Result.failure(e);
    }
  }

  Future<String> _getJavaExecutablePathAbs(int javaVersion) async {
    final result = await _javaRepository.getJavaExecutablePath(javaVersion);
    return switch (result) {
      Success<String>(value: final path) => path,
      Failure<String>() => 'java', // fallback
    };
  }

  bool _isAllowed(List<RuleApiModel>? rules) {
    if (rules == null || rules.isEmpty) return true;
    bool allowed = false;

    String currentOs = Platform.operatingSystem;
    if (currentOs == 'macos') currentOs = 'osx';

    final String abiString = Abi.current().toString();
    String currentArch;

    if (abiString.contains('arm64')) {
      currentArch = 'arm64';
    } else if (abiString.contains('arm')) {
      currentArch = 'arm';
    } else if (abiString.contains('ia32') || abiString.contains('x86')) {
      currentArch = 'x86';
    } else {
      currentArch = 'x64';
    }

    for (final rule in rules) {
      bool osMatch = true;
      bool archMatch = true;

      if (rule.os != null) {
        if (rule.os!.name != null && rule.os!.name != currentOs) {
          osMatch = false;
        }

        if (rule.os!.arch != null &&
            rule.os!.arch != currentArch &&
            rule.os!.arch != 'x86') {
          // Some x86 rules might apply to everyone if x86 compatibility exists,
          // but strict Mojang matching relies on specific strings.
          // For strict matching we will match exactly unless we know a better way.
          if (rule.os!.arch == currentArch) {
            archMatch = true;
          } else {
            archMatch = false;
          }
        } else if (rule.os!.arch != null && rule.os!.arch != currentArch) {
          archMatch = false;
        }
      }

      if (osMatch && archMatch) {
        if (rule.action == 'allow') {
          allowed = true;
        } else if (rule.action == 'disallow') {
          allowed = false;
        }
      }
    }
    return allowed;
  }

  List<String> _getJvmArguments(VersionRequirementsApiModel requirements) {
    final List<String> args = [];
    for (final arg in requirements.arguments) {
      if (arg.type == 'jvm' && _isAllowed(arg.rules)) {
        args.addAll(arg.values);
      }
    }
    return args;
  }

  List<String> _getGameArguments(VersionRequirementsApiModel requirements) {
    final List<String> args = [];
    for (final arg in requirements.arguments) {
      if (arg.type == 'game' && _isAllowed(arg.rules)) {
        args.addAll(arg.values);
      }
    }
    return args;
  }

  List<DownloadModel> _createAssetDownloads(
    String id,
    AssetIndexFileApiModel indexModel,
  ) {
    final assetDownloads = <DownloadModel>[];
    for (final entry in indexModel.objects.entries) {
      final hash = entry.value.hash;
      final size = entry.value.size;
      final prefix = hash.substring(0, 2);
      assetDownloads.add(
        DownloadModel(
          url: 'https://resources.download.minecraft.net/$prefix/$hash',
          path: 'assets/objects/$prefix/$hash',
          sha1: hash,
          expectedSize: size,
        ),
      );
    }
    return assetDownloads;
  }

  @override
  Future<Result<MinecraftProfileModel>> authenticate() {
    return _authenticateWithMicrosoft();
  }

  Future<Result<MinecraftProfileModel>> _authenticateWithMicrosoft() async {
    try {
      final msClient = MicrosoftApiClient();

      final accessResult = await msClient.getAccessToken();
      if (accessResult is Failure<String>) return Result.failure(accessResult.error);
      final accessToken = (accessResult as Success<String>).value;

      final xblResult = await msClient.exchangeXblToken(accessToken);
      if (xblResult is Failure<(String, String)>) return Result.failure(xblResult.error);
      final xblRec = (xblResult as Success<(String, String)>).value;
      final xblToken = xblRec.$1;
      final userHash = xblRec.$2;

      final xstsResult = await msClient.exchangeXstsToken(xblToken, userHash);
      if (xstsResult is Failure<String>) return Result.failure(xstsResult.error);
      final xstsToken = (xstsResult as Success<String>).value;

      final mcResult = await msClient.exchangeMinecraftToken(xstsToken, userHash);
      if (mcResult is Failure<String>) return Result.failure(mcResult.error);
      final mcToken = (mcResult as Success<String>).value;

      final profileResult = await msClient.getProfile(mcToken);
      if (profileResult is Failure<MinecraftProfileApiModel>) return Result.failure(profileResult.error);
      final profileApi = (profileResult as Success<MinecraftProfileApiModel>).value;

      final profile = MinecraftProfileModel(
        nickname: profileApi.name,
        uuid: profileApi.id,
        accessToken: mcToken,
        userType: 'mojang',
      );

      // Save profile to secure storage
      await _secureStorage.saveProfile(profile);

      return Result.success(profile);
    } on Exception catch (e) {
      _log.severe('authenticate error: $e');
      return Result.failure(Exception('authenticate failed: $e'));
    }
  }

  @override
  Future<Result<MinecraftProfileModel>> authenticateOffline(String username) {
    try {
      // Generate offline UUID using MD5(name-based UUID v3) similar to Java's
      final name = 'OfflinePlayer:$username';
      final bytes = crypto.md5.convert(utf8.encode(name)).bytes;

      // Set version to 3 (name-based MD5) and variant to RFC 4122
      final modified = List<int>.from(bytes);
      modified[6] = (modified[6] & 0x0f) | (3 << 4);
      modified[8] = (modified[8] & 0x3f) | 0x80;

      String toHex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      final hex = toHex(modified);
      final uuid = '${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';

      final profile = MinecraftProfileModel(
        nickname: username,
        uuid: uuid,
        accessToken: 'offline',
        userType: 'offline',
      );

      // Save profile to secure storage
      _secureStorage.saveProfile(profile);

      return Future.value(Result.success(profile));
    } on Exception catch (e) {
      _log.severe('authenticateOffline error: $e');
      return Future.value(Result.failure(Exception('authenticateOffline failed: $e')));
    }
  }

  @override
  Future<Result<MinecraftProfileModel>> getProfile() async {
    try {
      final profile = await _secureStorage.getProfile();
      if (profile != null) {
        _log.info('Successfully retrieved cached profile: ${profile.nickname}');
        return Result.success(profile);
      }
      return Result.failure(Exception('No cached profile found'));
    } on Exception catch (e) {
      _log.severe('getProfile error: $e');
      return Result.failure(Exception('getProfile failed: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _secureStorage.hasProfile();
    } catch (e) {
      _log.warning('isAuthenticated error: $e');
      return false;
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final ok = await _secureStorage.clearProfile();
      if (!ok) {
        return Result.failure(Exception('Failed to clear stored profile'));
      }
      _log.info('User logged out, profile cleared');
      return const Result.success(null);
    } on Exception catch (e) {
      _log.severe('logout error: $e');
      return Result.failure(Exception('logout failed: $e'));
    }
  }
}
