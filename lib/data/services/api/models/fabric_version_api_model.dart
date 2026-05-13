class FabricVersionApiModel {
  final String version;
  final bool stable;

  FabricVersionApiModel({required this.version, required this.stable});

  factory FabricVersionApiModel.fromJson(Map<String, dynamic> json) {
    final loader = json['loader'] as Map<String, dynamic>;
    return FabricVersionApiModel(
      version: loader['version'] as String,
      stable: loader['stable'] as bool? ?? false,
    );
  }
}
