import 'package:json_annotation/json_annotation.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';

part 'instance_model.g.dart';

@JsonSerializable()
class InstanceModel {
  final String id;
  final String name;
  @JsonKey(name: 'minecraftVersion')
  final String minecraftVersion;
  @JsonKey(name: 'modLoader')
  final String modLoader;
  @JsonKey(name: 'modLoaderVersion')
  final String modLoaderVersion;
  @JsonKey(name: 'isInstalled')
  final bool isInstalled;
  @JsonKey(name: 'installedContent', defaultValue: [])
  final List<InstalledContentModel> installedContent;
  @JsonKey(name: 'lastPlayed')
  final DateTime? lastPlayed;

  @JsonKey(name: 'javaMemory')
  final int? javaMemory;
  @JsonKey(name: 'windowWidth')
  final int? windowWidth;
  @JsonKey(name: 'windowHeight')
  final int? windowHeight;
  @JsonKey(name: 'customJavaPath')
  final String? customJavaPath;
  @JsonKey(name: 'jvmArguments')
  final String? jvmArguments;

  InstanceModel({
    required this.id,
    required this.name,
    required this.minecraftVersion,
    required this.modLoader,
    required this.modLoaderVersion,
    this.isInstalled = false,
    this.installedContent = const [],
    this.lastPlayed,
    this.javaMemory,
    this.windowWidth,
    this.windowHeight,
    this.customJavaPath,
    this.jvmArguments,
  });

  factory InstanceModel.fromJson(Map<String, dynamic> json) =>
      _$InstanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$InstanceModelToJson(this);

  InstanceModel copyWith({
    String? id,
    String? name,
    String? minecraftVersion,
    String? modLoader,
    String? modLoaderVersion,
    bool? isInstalled,
    List<InstalledContentModel>? installedContent,
    DateTime? lastPlayed,
    int? javaMemory,
    int? windowWidth,
    int? windowHeight,
    String? customJavaPath,
    String? jvmArguments,
  }) {
    return InstanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minecraftVersion: minecraftVersion ?? this.minecraftVersion,
      modLoader: modLoader ?? this.modLoader,
      modLoaderVersion: modLoaderVersion ?? this.modLoaderVersion,
      isInstalled: isInstalled ?? this.isInstalled,
      installedContent: installedContent ?? this.installedContent,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      javaMemory: javaMemory ?? this.javaMemory,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      customJavaPath: customJavaPath ?? this.customJavaPath,
      jvmArguments: jvmArguments ?? this.jvmArguments,
    );
  }
}
