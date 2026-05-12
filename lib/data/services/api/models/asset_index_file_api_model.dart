class AssetObjectApiModel {
  final String hash;
  final int size;

  AssetObjectApiModel({required this.hash, required this.size});

  factory AssetObjectApiModel.fromJson(Map<String, dynamic> json) {
    return AssetObjectApiModel(
      hash: json['hash'] as String,
      size: json['size'] as int,
    );
  }
}

class AssetIndexFileApiModel {
  final Map<String, AssetObjectApiModel> objects;

  AssetIndexFileApiModel({required this.objects});

  factory AssetIndexFileApiModel.fromJson(Map<String, dynamic> json) {
    final objectsJson = json['objects'] as Map<String, dynamic>;
    final objects = objectsJson.map(
      (key, value) => MapEntry(key, AssetObjectApiModel.fromJson(value as Map<String, dynamic>)),
    );
    return AssetIndexFileApiModel(objects: objects);
  }
}
