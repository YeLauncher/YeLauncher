import 'package:json_annotation/json_annotation.dart';

part 'content_dependency.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ContentDependency {
  final String? versionId;
  final String? projectId;
  final String? fileName;
  final String dependencyType;

  const ContentDependency({
    this.versionId,
    this.projectId,
    this.fileName,
    required this.dependencyType,
  });

  factory ContentDependency.fromJson(Map<String, dynamic> json) =>
      _$ContentDependencyFromJson(json);

  Map<String, dynamic> toJson() => _$ContentDependencyToJson(this);
}
