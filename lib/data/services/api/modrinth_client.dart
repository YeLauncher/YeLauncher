import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:yelauncher/data/services/api/content_provider.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/utilities/result.dart';

class ModrinthClient implements ContentProvider {
  final _log = Logger('ModrinthClient');
  final String _baseUrl = 'https://api.modrinth.com/v2';
  final Map<String, String> _headers = {
    'User-Agent': 'YeLauncher/1.0.0',
  };
  final http.Client _httpClient;

  ModrinthClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  @override
  Future<Result<List<ContentItem>>> searchContent({
    required String query,
    required String projectType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        if (query.isNotEmpty) 'query': query,
        'facets': '[["project_type:$projectType"]]',
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final hits = json['hits'] as List;
        return Success(hits.map((e) => ContentItem.fromJson(e)).toList());
      } else {
        return Failure(Exception('Failed to search: ${response.statusCode}'));
      }
    } catch (e, st) {
      _log.severe('Search failed', e, st);
      return Failure(Exception('Search failed: $e'));
    }
  }

  @override
  Future<Result<ContentItem>> getContent(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/project/$id');
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Success(ContentItem.fromJson(json));
      } else {
        return Failure(Exception('Failed to get content: ${response.statusCode}'));
      }
    } catch (e, st) {
      _log.severe('Get content failed', e, st);
      return Failure(Exception('Get content failed: $e'));
    }
  }

  @override
  Future<Result<List<ContentVersion>>> getVersions(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/project/$id/version');
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List json = jsonDecode(response.body);
        return Success(json.map((e) => ContentVersion.fromJson(e)).toList());
      } else {
        return Failure(Exception('Failed to get versions: ${response.statusCode}'));
      }
    } catch (e, st) {
      _log.severe('Get versions failed', e, st);
      return Failure(Exception('Get versions failed: $e'));
    }
  }
}
