// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentVersion _$ContentVersionFromJson(Map<String, dynamic> json) =>
    ContentVersion(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      versionNumber: json['version_number'] as String,
      gameVersions: (json['game_versions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      loaders: (json['loaders'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      files: (json['files'] as List<dynamic>)
          .map((e) => ContentFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContentVersionToJson(ContentVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'name': instance.name,
      'version_number': instance.versionNumber,
      'game_versions': instance.gameVersions,
      'loaders': instance.loaders,
      'files': instance.files,
    };
