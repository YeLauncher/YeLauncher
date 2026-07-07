import 'package:json_annotation/json_annotation.dart';

part 'content_gallery_image.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ContentGalleryImage {
  final String url;
  final String? name;
  final String? description;

  const ContentGalleryImage({
    required this.url,
    this.name,
    this.description,
  });

  factory ContentGalleryImage.fromJson(Map<String, dynamic> json) =>
      _$ContentGalleryImageFromJson(json);

  Map<String, dynamic> toJson() => _$ContentGalleryImageToJson(this);
}
