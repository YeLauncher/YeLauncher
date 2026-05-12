class ClientApiModel {
  final String url;
  final String sha1;
  final int size;

  ClientApiModel({required this.url, required this.sha1, required this.size});

  factory ClientApiModel.fromJson(Map<String, dynamic> json) {
    return ClientApiModel(
      url: json['url'] as String,
      sha1: json['sha1'] as String,
      size: json['size'] as int,
    );
  }
}
