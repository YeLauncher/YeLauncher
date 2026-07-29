// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_dependency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentDependency _$ContentDependencyFromJson(Map<String, dynamic> json) =>
    ContentDependency(
      versionId: json['version_id'] as String?,
      projectId: json['project_id'] as String?,
      fileName: json['file_name'] as String?,
      dependencyType: json['dependency_type'] as String,
    );

Map<String, dynamic> _$ContentDependencyToJson(ContentDependency instance) =>
    <String, dynamic>{
      'version_id': instance.versionId,
      'project_id': instance.projectId,
      'file_name': instance.fileName,
      'dependency_type': instance.dependencyType,
    };
