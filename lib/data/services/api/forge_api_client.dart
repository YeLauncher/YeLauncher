import 'dart:convert';
import 'dart:io';

import 'package:yelauncher/data/services/api/models/forge_version_api_model.dart';

class ForgeApiClient {
  final HttpClient Function() _httpClientFactory;
  final String _baseUrl;

  ForgeApiClient({HttpClient Function()? httpClientFactory, String? baseUrl})
    : _httpClientFactory = httpClientFactory ?? HttpClient.new,
      _baseUrl = baseUrl ?? 'https://bmclapi2.bangbang93.com/forge/minecraft';

  Future<List<ForgeVersionApiModel>> getVersions(
    String minecraftVersion,
  ) async {
    final HttpClient client = _httpClientFactory();
    final Uri uri = Uri.parse('$_baseUrl/$minecraftVersion');
    final HttpClientRequest request = await client.getUrl(uri);
    final HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();

    final List<dynamic> jsonList = jsonDecode(body) as List<dynamic>;
    return jsonList
        .map((e) => ForgeVersionApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
