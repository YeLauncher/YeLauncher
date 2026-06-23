import 'package:yelauncher/data/services/api/content_provider.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/utilities/result.dart';

class ContentRepository {
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
      return Result.success(_searchCache[cacheKey]!);
    }

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
      return Result.success(_contentCache[id]!);
    }

    final result = await _provider.getContent(id);

    if (result is Success<ContentItem>) {
      _contentCache[id] = result.value;
    }

    return result;
  }

  Future<Result<List<ContentVersion>>> getVersions(String id) async {
    if (_versionsCache.containsKey(id)) {
      return Result.success(_versionsCache[id]!);
    }

    final result = await _provider.getVersions(id);

    if (result is Success<List<ContentVersion>>) {
      _versionsCache[id] = result.value;
    }

    return result;
  }
}
