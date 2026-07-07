import 'dart:convert';
import 'dart:io';

import 'package:yelauncher/data/services/api/models/version_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_manifest_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/api/strategies/version_21_requirements_strategy.dart';
import 'package:yelauncher/data/services/api/strategies/version_requirements_strategy.dart';
import 'package:yelauncher/data/services/api/strategies/version_4_requirements_strategy.dart';
import 'package:yelauncher/data/services/api/models/asset_index_file_api_model.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:logging/logging.dart';

class MinecraftApiClient {
  final _log = Logger('MinecraftApiClient');
  final HttpClient Function() _httpClientFactory;
  final String _baseUrl;
  final List<VersionRequirementsStrategy> _strategies = [
    Version21RequirementsStrategy(),
    Version4RequirementsStrategy(),
  ];
  VersionManifestApiModel? _cachedManifest;

  MinecraftApiClient({
    HttpClient Function()? httpClientFactory,
    required String baseUrl,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new,
       _baseUrl = baseUrl;

  Future<Result<VersionManifestApiModel>> getManifest() async {
    if (_cachedManifest != null) {
      return Result.success(_cachedManifest!);
    }
    try {
      final HttpClient client = _httpClientFactory();
      final HttpClientRequest request = await client.getUrl(
        Uri.parse(_baseUrl),
      );
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      final manifest = VersionManifestApiModel.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
      _cachedManifest = manifest;
      return Result.success(manifest);
    } on Exception catch (e, stack) {
      _log.severe('Failed to get Minecraft manifest', e, stack);
      return Result.failure(e);
    }
  }

  Future<Result<VersionApiModel>> getVersion(String id) async {
    final result = await getManifest();
    switch (result) {
      case Success<VersionManifestApiModel>():
        try {
          return Result.success(
            result.value.versions.firstWhere((version) => version.id == id),
          );
        } on StateError catch(e, stack) {
          _log.severe('Minecraft version not found: $id', e, stack);
          return Result.failure(Exception('Version not found: $id'));
        }
      case Failure<VersionManifestApiModel>():
        return Result.failure(result.error);
    }
  }

  Future<Result<VersionRequirementsApiModel>> getRequirements(
    VersionApiModel version,
  ) async {
    try {
      final HttpClient client = _httpClientFactory();
      final HttpClientRequest request = await client.getUrl(
        Uri.parse(version.url),
      );
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      var json = jsonDecode(body) as Map<String, dynamic>;
      var minumumLauncherVersion = json["minimumLauncherVersion"];
      var strategy = _strategies.firstWhere(
        (strategy) => strategy.isCompatible(
          minumumLauncherVersion, // minimum Minecraft Launcher in json
        ),
      );
      return strategy.parseVersionPrerequisites(json);
    } on Exception catch (e, stack) {
      _log.severe('Failed to get Minecraft version requirements for ${version.id}', e, stack);
      return Result.failure(e);
    }
  }

  Future<Result<AssetIndexFileApiModel>> getAssetIndex(String url) async {
    try {
      final HttpClient client = _httpClientFactory();
      final HttpClientRequest request = await client.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      return Result.success(
        AssetIndexFileApiModel.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        ),
      );
    } on Exception catch (e, stack) {
      _log.severe('Failed to get asset index from $url', e, stack);
      return Result.failure(e);
    }
  }
}
