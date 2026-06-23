import 'package:json_annotation/json_annotation.dart';

part 'content_file.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ContentFile {
  final String url;
  final String filename;
  final bool primary;

  const ContentFile({
    required this.url,
    required this.filename,
    required this.primary,
  });

  factory ContentFile.fromJson(Map<String, dynamic> json) =>
      _$ContentFileFromJson(json);

  Map<String, dynamic> toJson() => _$ContentFileToJson(this);
}
