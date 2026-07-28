import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/utilities/result.dart';

abstract interface class ContentProvider {
  Future<Result<List<ContentItem>>> searchContent({
    required String query,
    required String projectType,
    List<String> versions = const [],
    List<String> modLoaders = const [],
    List<String> categories = const [],
    String sortOrder = 'relevance',
    int limit = 20,
    int offset = 0,
  });

  Future<Result<ContentItem>> getContent(String id);

  Future<Result<List<ContentVersion>>> getVersions(String id);

  Future<Result<ContentVersion>> getVersion(String versionId);

  Future<Result<List<ContentItem>>> getProjectDependencies(String id);
}
