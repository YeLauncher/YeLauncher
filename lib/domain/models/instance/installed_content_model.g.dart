// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstalledContentModel _$InstalledContentModelFromJson(
  Map<String, dynamic> json,
) => InstalledContentModel(
  projectId: json['project_id'] as String,
  versionId: json['version_id'] as String,
  filename: json['filename'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$InstalledContentModelToJson(
  InstalledContentModel instance,
) => <String, dynamic>{
  'project_id': instance.projectId,
  'version_id': instance.versionId,
  'filename': instance.filename,
  'title': instance.title,
  'type': instance.type,
};
