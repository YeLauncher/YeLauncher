class LatestVersionsApiModel {
  final String release;
  final String snapshot;

  LatestVersionsApiModel({required this.release, required this.snapshot});

  factory LatestVersionsApiModel.fromJson(Map<String, dynamic> json) {
    return LatestVersionsApiModel(
      release: json['release'] as String,
      snapshot: json['snapshot'] as String,
    );
  }
}
