import 'package:json_annotation/json_annotation.dart';

part 'installed_content_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class InstalledContentModel {
  final String projectId;
  final String versionId;
  final String filename;
  final String title;
  final String type;
  final String author;
  final String version;
  final String? iconUrl;

  const InstalledContentModel({
    required this.projectId,
    required this.versionId,
    required this.filename,
    required this.title,
    required this.type,
    this.author = 'Unknown Author',
    this.version = 'Unknown Version',
    this.iconUrl,
  });

  factory InstalledContentModel.fromJson(Map<String, dynamic> json) =>
      _$InstalledContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$InstalledContentModelToJson(this);

  InstalledContentModel copyWith({
    String? projectId,
    String? versionId,
    String? filename,
    String? title,
    String? type,
    String? author,
    String? version,
    String? iconUrl,
  }) {
    return InstalledContentModel(
      projectId: projectId ?? this.projectId,
      versionId: versionId ?? this.versionId,
      filename: filename ?? this.filename,
      title: title ?? this.title,
      type: type ?? this.type,
      author: author ?? this.author,
      version: version ?? this.version,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }
}
