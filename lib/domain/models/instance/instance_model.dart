class InstanceModel {
  final String id;
  final String name;
  final String minecraftVersion;
  final String modLoader;
  final String modLoaderVersion;
  final bool isInstalled;

  InstanceModel({
    required this.id,
    required this.name,
    required this.minecraftVersion,
    required this.modLoader,
    required this.modLoaderVersion,
    this.isInstalled = false,
  });

  factory InstanceModel.fromJson(Map<String, dynamic> json) {
    return InstanceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      minecraftVersion: json['minecraftVersion'] as String,
      modLoader: json['modLoader'] as String,
      modLoaderVersion: json['modLoaderVersion'] as String,
      isInstalled: json['isInstalled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'minecraftVersion': minecraftVersion,
      'modLoader': modLoader,
      'modLoaderVersion': modLoaderVersion,
      'isInstalled': isInstalled,
    };
  }

  InstanceModel copyWith({
    String? id,
    String? name,
    String? minecraftVersion,
    String? modLoader,
    String? modLoaderVersion,
    bool? isInstalled,
  }) {
    return InstanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minecraftVersion: minecraftVersion ?? this.minecraftVersion,
      modLoader: modLoader ?? this.modLoader,
      modLoaderVersion: modLoaderVersion ?? this.modLoaderVersion,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}
