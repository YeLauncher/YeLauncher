import 'package:yelauncher/data/services/api/content_provider.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:logging/logging.dart';
import 'package:yelauncher/utilities/result.dart';

class ContentRepository {
  final _log = Logger('ContentRepository');
  final ContentProvider _provider;

  // In-memory caches
  final Map<String, List<ContentItem>> _searchCache = {};
  final Map<String, ContentItem> _contentCache = {};
  final Map<String, List<ContentVersion>> _versionsCache = {};

  ContentRepository({required ContentProvider provider}) : _provider = provider;

  Future<Result<List<ContentItem>>> searchContent({
    required String query,
    required String projectType,
    int limit = 20,
    int offset = 0,
  }) async {
    final cacheKey = '${query}_${projectType}_${limit}_$offset';
    if (_searchCache.containsKey(cacheKey)) {
      _log.fine('Returning cached search results for query: $query');
      return Result.success(_searchCache[cacheKey]!);
    }

    _log.info('Searching content for query: $query, projectType: $projectType');

    final result = await _provider.searchContent(
      query: query,
      projectType: projectType,
      limit: limit,
      offset: offset,
    );

    if (result is Success<List<ContentItem>>) {
      _searchCache[cacheKey] = result.value;
    }

    return result;
  }

  Future<Result<ContentItem>> getContent(String id) async {
    if (_contentCache.containsKey(id)) {
      _log.fine('Returning cached content for id: $id');
      return Result.success(_contentCache[id]!);
    }

    _log.info('Fetching content for id: $id');

    final result = await _provider.getContent(id);

    if (result is Success<ContentItem>) {
      _contentCache[id] = result.value;
    }

    return result;
  }

  Future<Result<List<ContentVersion>>> getVersions(String id) async {
    if (_versionsCache.containsKey(id)) {
      _log.fine('Returning cached versions for id: $id');
      return Result.success(_versionsCache[id]!);
    }

    _log.info('Fetching versions for id: $id');

    final result = await _provider.getVersions(id);

    if (result is Success<List<ContentVersion>>) {
      _versionsCache[id] = result.value;
    }

    return result;
  }
}
