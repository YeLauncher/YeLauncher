// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstanceModel _$InstanceModelFromJson(Map<String, dynamic> json) =>
    InstanceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      minecraftVersion: json['minecraftVersion'] as String,
      modLoader: json['modLoader'] as String,
      modLoaderVersion: json['modLoaderVersion'] as String,
      isInstalled: json['isInstalled'] as bool? ?? false,
      installedContent:
          (json['installedContent'] as List<dynamic>?)
              ?.map(
                (e) =>
                    InstalledContentModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      lastPlayed: json['lastPlayed'] == null
          ? null
          : DateTime.parse(json['lastPlayed'] as String),
      javaMemory: (json['javaMemory'] as num?)?.toInt(),
      windowWidth: (json['windowWidth'] as num?)?.toInt(),
      windowHeight: (json['windowHeight'] as num?)?.toInt(),
      customJavaPath: json['customJavaPath'] as String?,
      jvmArguments: json['jvmArguments'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$InstanceModelToJson(InstanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'minecraftVersion': instance.minecraftVersion,
      'modLoader': instance.modLoader,
      'modLoaderVersion': instance.modLoaderVersion,
      'isInstalled': instance.isInstalled,
      'installedContent': instance.installedContent,
      'lastPlayed': instance.lastPlayed?.toIso8601String(),
      'javaMemory': instance.javaMemory,
      'windowWidth': instance.windowWidth,
      'windowHeight': instance.windowHeight,
      'customJavaPath': instance.customJavaPath,
      'jvmArguments': instance.jvmArguments,
      'icon': instance.icon,
      'color': instance.color,
    };
