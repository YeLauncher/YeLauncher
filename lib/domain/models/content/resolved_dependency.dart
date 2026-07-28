import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';

class ResolvedDependency {
  final ContentItem item;
  final ContentVersion version;

  const ResolvedDependency({
    required this.item,
    required this.version,
  });
}
