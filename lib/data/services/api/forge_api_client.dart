import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:yelauncher/data/services/api/models/forge_version_api_model.dart';

class ForgeApiClient {
  final HttpClient Function() _httpClientFactory;
  final String _metadataUrl;
  final String _promotionsUrl;

  ForgeApiClient({HttpClient Function()? httpClientFactory, String? baseUrl})
    : _httpClientFactory = httpClientFactory ?? HttpClient.new,
      _metadataUrl =
          baseUrl ?? 'https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml',
      _promotionsUrl =
          'https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json';

  Future<List<ForgeVersionApiModel>> getVersions(
    String minecraftVersion,
  ) async {
    final body = await _getString(_metadataUrl);
    final matches = RegExp(r'<version>([^<]+)</version>').allMatches(body);
    return matches
        .map((match) => match.group(1)!)
        .where((version) => version.startsWith('$minecraftVersion-'))
        .map((version) => ForgeVersionApiModel(version: version.split('-').sublist(1).join('-')))
        .toList();
  }

  Future<String?> getLatestVersion(String minecraftVersion) async {
    final promos = await _getPromotions();
    return promos['$minecraftVersion-latest'];
  }

  Future<String?> getRecommendedVersion(String minecraftVersion) async {
    final promos = await _getPromotions();
    return promos['$minecraftVersion-recommended'];
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
    } catch (_) {
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
}
