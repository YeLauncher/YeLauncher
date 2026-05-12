class ForgeVersionApiModel {
  final String version;

  ForgeVersionApiModel({
    required this.version,
  });

  factory ForgeVersionApiModel.fromJson(Map<String, dynamic> json) {
    return ForgeVersionApiModel(
      version: json['version'] as String,
    );
  }
}
