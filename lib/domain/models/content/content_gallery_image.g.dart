// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_gallery_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentGalleryImage _$ContentGalleryImageFromJson(Map<String, dynamic> json) =>
    ContentGalleryImage(
      url: json['url'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ContentGalleryImageToJson(
  ContentGalleryImage instance,
) => <String, dynamic>{
  'url': instance.url,
  'name': instance.name,
  'description': instance.description,
};
