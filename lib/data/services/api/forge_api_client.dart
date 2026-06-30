import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:yelauncher/data/services/api/models/forge_version_api_model.dart';
import 'package:logging/logging.dart';

class ForgeApiClient {
  final _log = Logger('ForgeApiClient');
  final HttpClient Function() _httpClientFactory;
  final String _metadataUrl;
  final String _promotionsUrl;
  final String _downloadBaseUrl;

  ForgeApiClient({
    HttpClient Function()? httpClientFactory,
    String? baseUrl,
    String? downloadBaseUrl,
  })
    : _httpClientFactory = httpClientFactory ?? HttpClient.new,
      _metadataUrl =
          baseUrl ?? 'https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml',
      _promotionsUrl =
          'https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json',
      _downloadBaseUrl =
          _normalizeBaseUrl(
            downloadBaseUrl ?? 'https://maven.minecraftforge.net/net/minecraftforge/forge',
          );

  Future<List<ForgeVersionApiModel>> getVersions(
    String minecraftVersion,
  ) async {
    _log.info('Fetching Forge versions for $minecraftVersion');
    try {
      final body = await _getString(_metadataUrl);
      final matches = RegExp(r'<version>([^<]+)</version>').allMatches(body);
      return matches
          .map((match) => match.group(1)!)
          .where((version) => version.startsWith('$minecraftVersion-'))
          .map((version) => ForgeVersionApiModel(version: version.split('-').sublist(1).join('-')))
          .toList();
    } catch (e, stack) {
      _log.severe('Failed to fetch Forge versions for $minecraftVersion', e, stack);
      rethrow;
    }
  }

  Future<String?> getLatestVersion(String minecraftVersion) async {
    final promos = await _getPromotions();
    final promoVersion = promos['$minecraftVersion-latest'];
    if (promoVersion == null) return null;
    return _resolveRealForgeVersion(minecraftVersion, promoVersion);
  }

  Future<String?> getRecommendedVersion(String minecraftVersion) async {
    final promos = await _getPromotions();
    final promoVersion = promos['$minecraftVersion-recommended'];
    if (promoVersion == null) return null;
    return _resolveRealForgeVersion(minecraftVersion, promoVersion);
  }

  Future<String> _resolveRealForgeVersion(String minecraftVersion, String promoVersion) async {
    try {
      final versions = await getVersions(minecraftVersion);
      for (final v in versions) {
        if (v.version == promoVersion || v.version == '$promoVersion-$minecraftVersion') {
          return v.version;
        }
      }
    } catch (e, stack) {
      _log.warning('Failed to resolve real Forge version for $promoVersion: $e', e, stack);
      // Fallback if metadata fails
    }
    return promoVersion;
  }

  String getInstallerDownloadUrl(String minecraftVersion, String forgeVersion) {
    final fullVersion = '$minecraftVersion-$forgeVersion';
    return '$_downloadBaseUrl/$fullVersion/forge-$fullVersion-installer.jar';
  }

  Future<Map<String, String>> _getPromotions() async {
    final body = await _getString(_promotionsUrl);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final promos = decoded['promos'] as Map<String, dynamic>;
    return promos.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<String> _getString(String url) async {
    try {
      final client = _httpClientFactory();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
    } catch (e, stack) {
      _log.warning('Failed to fetch $_metadataUrl online, falling back to local asset: $e', e, stack);
      return _loadFallback(url);
    }
  }

  Future<String> _loadFallback(String url) async {
    final fallbackAsset = switch (url) {
      'https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml' =>
        Assets.forgeMavenMetadata,
      'https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json' =>
        Assets.forgePromotionsSlim,
      _ => throw Exception('No fallback available for $url'),
    };

    return await rootBundle.loadString(fallbackAsset);
  }

  static String _normalizeBaseUrl(String value) {
    return value.replaceAll(RegExp(r'/+$'), '');
  }
}
