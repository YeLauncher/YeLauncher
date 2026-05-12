class MinecraftVersionModel {
  final String id;
  final String type;
  final DateTime releaseTime;

  MinecraftVersionModel({
    required this.id,
    required this.type,
    required this.releaseTime,
  });

  factory MinecraftVersionModel.fromJson(Map<String, dynamic> json) {
    return MinecraftVersionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      releaseTime: DateTime.parse(json['releaseTime'] as String),
    );
  }
}
