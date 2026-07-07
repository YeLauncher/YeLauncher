// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) => ContentItem(
  id: ContentItem._readId(json, 'id') as String,
  slug: json['slug'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  projectType: json['project_type'] as String,
  iconUrl: json['icon_url'] as String?,
  downloads: (json['downloads'] as num?)?.toInt(),
  organization: json['organization'] as String?,
  teamId: json['team_id'] as String?,
  author: json['author'] as String?,
  loaders: (json['loaders'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  gameVersions: (json['game_versions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  gallery: (ContentItem._readGallery(json, 'gallery') as List<dynamic>?)
      ?.map((e) => ContentGalleryImage.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ContentItemToJson(ContentItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'title': instance.title,
      'description': instance.description,
      'project_type': instance.projectType,
      'icon_url': instance.iconUrl,
      'downloads': instance.downloads,
      'organization': instance.organization,
      'team_id': instance.teamId,
      'author': instance.author,
      'loaders': instance.loaders,
      'game_versions': instance.gameVersions,
      'gallery': instance.gallery,
    };
