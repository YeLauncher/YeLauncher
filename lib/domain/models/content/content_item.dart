import 'package:json_annotation/json_annotation.dart';
import 'package:yelauncher/domain/models/content/content_gallery_image.dart';

part 'content_item.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ContentItem {
  @JsonKey(readValue: _readId)
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? body;
  final String projectType;
  final String? iconUrl;
  final int? downloads;
  final String? organization;
  final String? teamId;
  final String? author;
  @JsonKey(readValue: _readLoaders)
  final List<String>? loaders;
  @JsonKey(readValue: _readGameVersions)
  final List<String>? gameVersions;
  @JsonKey(readValue: _readGallery)
  final List<ContentGalleryImage>? gallery;

  static Object? _readId(Map json, String key) => json['project_id'] ?? json['id'];

  static Object? _readLoaders(Map json, String key) {
    if (json.containsKey('loaders')) return json['loaders'];
    if (json.containsKey('display_categories')) {
      final cats = List<String>.from(json['display_categories'] as List);
      final loaders = cats.where((c) => const ['fabric', 'forge', 'neoforge', 'quilt', 'liteloader'].contains(c.toLowerCase())).toList();
      if (loaders.isNotEmpty) return loaders;
    }
    if (json.containsKey('categories')) {
      final cats = List<String>.from(json['categories'] as List);
      final loaders = cats.where((c) => const ['fabric', 'forge', 'neoforge', 'quilt', 'liteloader'].contains(c.toLowerCase())).toList();
      if (loaders.isNotEmpty) return loaders;
    }
    return json[key];
  }

  static Object? _readGameVersions(Map json, String key) {
    if (json.containsKey('game_versions')) return json['game_versions'];
    if (json.containsKey('versions')) return json['versions'];
    return json[key];
  }

  static Object? _readGallery(Map json, String key) {
    if (json[key] is List) {
      final list = json[key] as List;
      if (list.isEmpty) return null;
      if (list.first is String) {
        return list.map((url) => {'url': url}).toList();
      }
      return list;
    }
    return json[key];
  }

  const ContentItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.body,
    required this.projectType,
    this.iconUrl,
    this.downloads,
    this.organization,
    this.teamId,
    this.author,
    this.loaders,
    this.gameVersions,
    this.gallery,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);

  Map<String, dynamic> toJson() => _$ContentItemToJson(this);
}
