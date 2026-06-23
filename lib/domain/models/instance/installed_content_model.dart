import 'package:json_annotation/json_annotation.dart';

part 'installed_content_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class InstalledContentModel {
  final String projectId;
  final String versionId;
  final String filename;
  final String title;
  final String type;

  const InstalledContentModel({
    required this.projectId,
    required this.versionId,
    required this.filename,
    required this.title,
    required this.type,
  });

  factory InstalledContentModel.fromJson(Map<String, dynamic> json) =>
      _$InstalledContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$InstalledContentModelToJson(this);
}
