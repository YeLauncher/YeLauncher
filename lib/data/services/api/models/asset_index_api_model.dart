class AssetIndexApiModel {
  final String id;
  final String url;
  final String sha1;
  final int size;
  final int totalSize;

  AssetIndexApiModel({
    required this.id,
    required this.url,
    required this.sha1,
    required this.size,
    required this.totalSize,
  });

  factory AssetIndexApiModel.fromJson(Map<String, dynamic> json) {
    return AssetIndexApiModel(
      id: json['id'] as String,
      url: json['url'] as String,
      sha1: json['sha1'] as String,
      size: json['size'] as int,
      totalSize: json['totalSize'] as int,
    );
  }
}
