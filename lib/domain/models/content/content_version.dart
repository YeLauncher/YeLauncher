import 'package:json_annotation/json_annotation.dart';
import 'package:yelauncher/domain/models/content/content_file.dart';

part 'content_version.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ContentVersion {
  final String id;
  final String projectId;
  final String name;
  final String versionNumber;
  final List<String> gameVersions;
  final List<String> loaders;
  final List<ContentFile> files;

  const ContentVersion({
    required this.id,
    required this.projectId,
    required this.name,
    required this.versionNumber,
    required this.gameVersions,
    required this.loaders,
    required this.files,
  });

  factory ContentVersion.fromJson(Map<String, dynamic> json) =>
      _$ContentVersionFromJson(json);

  Map<String, dynamic> toJson() => _$ContentVersionToJson(this);
}
