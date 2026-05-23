class MinecraftProfileSkinApiModel {
  final String id;
  final String state;
  final String url;
  final String variant; // "CLASSIC" or "SLIM"

  MinecraftProfileSkinApiModel({
    required this.id,
    required this.state,
    required this.url,
    required this.variant,
  });

  factory MinecraftProfileSkinApiModel.fromJson(Map<String, dynamic> json) {
    return MinecraftProfileSkinApiModel(
      id: json['id'] as String,
      state: json['state'] as String,
      url: json['url'] as String,
      variant: (json['variant'] ?? 'CLASSIC') as String,
    );
  }
}

class MinecraftProfileCapeApiModel {
  final String id;
  final String state;
  final String url;

  MinecraftProfileCapeApiModel({
    required this.id,
    required this.state,
    required this.url,
  });

  factory MinecraftProfileCapeApiModel.fromJson(Map<String, dynamic> json) {
    return MinecraftProfileCapeApiModel(
      id: json['id'] as String,
      state: json['state'] as String,
      url: json['url'] as String,
    );
  }
}

class MinecraftProfileApiModel {
  final String id;
  final String name;
  final List<MinecraftProfileSkinApiModel> skins;
  final List<MinecraftProfileCapeApiModel> capes;

  MinecraftProfileApiModel({
    required this.id,
    required this.name,
    required this.skins,
    required this.capes,
  });

  factory MinecraftProfileApiModel.fromJson(Map<String, dynamic> json) {
    final skinsJson = json['skins'] as List<dynamic>? ?? <dynamic>[];
    final capesJson = json['capes'] as List<dynamic>? ?? <dynamic>[];

    return MinecraftProfileApiModel(
      id: json['id'] as String,
      name: json['name'] as String,
      skins: skinsJson.map((e) => MinecraftProfileSkinApiModel.fromJson(e as Map<String, dynamic>)).toList(),
      capes: capesJson.map((e) => MinecraftProfileCapeApiModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

