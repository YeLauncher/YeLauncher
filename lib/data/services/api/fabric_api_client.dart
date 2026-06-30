import 'dart:convert';
import 'dart:io';

import 'package:yelauncher/data/services/api/models/fabric_version_api_model.dart';
import 'package:logging/logging.dart';

class FabricApiClient {
  final _log = Logger('FabricApiClient');
  final HttpClient Function() _httpClientFactory;
  final String _baseUrl;

  FabricApiClient({HttpClient Function()? httpClientFactory, String? baseUrl})
    : _httpClientFactory = httpClientFactory ?? HttpClient.new,
      _baseUrl = baseUrl ?? 'https://meta.fabricmc.net/v2/versions/loader';

  Future<List<FabricVersionApiModel>> getVersions(
    String minecraftVersion,
  ) async {
    _log.info('Fetching Fabric versions for $minecraftVersion');
    try {
      final HttpClient client = _httpClientFactory();
      final Uri uri = Uri.parse('$_baseUrl/$minecraftVersion');
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();

      final List<dynamic> jsonList = jsonDecode(body) as List<dynamic>;
      return jsonList
          .map((e) => FabricVersionApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      _log.severe('Failed to fetch Fabric versions for $minecraftVersion', e, stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfileJson(
    String minecraftVersion,
    String loaderVersion,
  ) async {
    _log.info('Fetching Fabric profile json for $minecraftVersion / $loaderVersion');
    try {
      final HttpClient client = _httpClientFactory();
      final Uri uri = Uri.parse('$_baseUrl/$minecraftVersion/$loaderVersion/profile/json');
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e, stack) {
      _log.severe('Failed to fetch Fabric profile json for $minecraftVersion / $loaderVersion', e, stack);
      rethrow;
    }
  }
}
