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

  InstanceModel({
    required this.id,
    required this.name,
    required this.minecraftVersion,
    required this.modLoader,
    required this.modLoaderVersion,
    this.isInstalled = false,
    this.installedContent = const [],
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
  }) {
    return InstanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minecraftVersion: minecraftVersion ?? this.minecraftVersion,
      modLoader: modLoader ?? this.modLoader,
      modLoaderVersion: modLoaderVersion ?? this.modLoaderVersion,
      isInstalled: isInstalled ?? this.isInstalled,
      installedContent: installedContent ?? this.installedContent,
    );
  }
}
