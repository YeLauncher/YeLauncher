// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentFile _$ContentFileFromJson(Map<String, dynamic> json) => ContentFile(
  url: json['url'] as String,
  filename: json['filename'] as String,
  primary: json['primary'] as bool,
);

Map<String, dynamic> _$ContentFileToJson(ContentFile instance) =>
    <String, dynamic>{
      'url': instance.url,
      'filename': instance.filename,
      'primary': instance.primary,
    };
