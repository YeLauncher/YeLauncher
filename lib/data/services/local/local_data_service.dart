import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/data/services/api/models/fabric_version_api_model.dart';
import 'package:yelauncher/data/services/api/models/forge_version_api_model.dart';

class LocalDataService {
  Future<List<MinecraftVersionModel>> getVersions() async {
    final json = (await _loadStringAsset(Assets.versionManifest));
    return json.map((json) => MinecraftVersionModel.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> _loadStringAsset(String asset) async {
    final localData = await rootBundle.loadString(asset);
    final decodedMap = jsonDecode(localData) as Map<String, dynamic>;
    return (decodedMap["versions"] as List).cast<Map<String, dynamic>>();
  }

  Future<List<FabricVersionApiModel>> getFabricVersions(
    String minecraftVersion,
  ) async {
    if (minecraftVersion != '1.18.2') return [];
    final localData = await rootBundle.loadString(Assets.fabric1182);
    final jsonList = jsonDecode(localData) as List<dynamic>;
    return jsonList
        .map(
          (json) =>
              FabricVersionApiModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ForgeVersionApiModel>> getForgeVersions(
    String minecraftVersion,
  ) async {
    final metadata = await rootBundle.loadString(Assets.forgeMavenMetadata);
    final matches = RegExp(r'<version>([^<]+)</version>').allMatches(metadata);
    return matches
        .map((match) => match.group(1)!)
        .where((version) => version.startsWith('$minecraftVersion-'))
        .map((version) => ForgeVersionApiModel(version: version.split('-').sublist(1).join('-')))
        .toList();
  }

  Future<String?> getForgeLatestVersion(String minecraftVersion) async {
    final promos = await _loadForgePromotions();
    return promos['$minecraftVersion-latest'];
  }

  Future<String?> getForgeRecommendedVersion(String minecraftVersion) async {
    final promos = await _loadForgePromotions();
    return promos['$minecraftVersion-recommended'];
  }

  Future<Map<String, String>> _loadForgePromotions() async {
    final localData = await rootBundle.loadString(Assets.forgePromotionsSlim);
    final decoded = jsonDecode(localData) as Map<String, dynamic>;
    final promos = decoded['promos'] as Map<String, dynamic>;
    return promos.map((key, value) => MapEntry(key, value.toString()));
  }
}
