import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/utilities/result.dart';

abstract interface class ContentProvider {
  Future<Result<List<ContentItem>>> searchContent({
    required String query,
    required String projectType,
    int limit = 20,
    int offset = 0,
  });

  Future<Result<ContentItem>> getContent(String id);

  Future<Result<List<ContentVersion>>> getVersions(String id);
}
