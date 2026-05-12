class VersionApiModel {
  final String id;
  final String type;
  final String url;
  final DateTime time;
  final DateTime releaseTime;
  final int complianceLevel;

  VersionApiModel({
    required this.id,
    required this.type,
    required this.url,
    required this.time,
    required this.releaseTime,
    required this.complianceLevel,
  });

  factory VersionApiModel.fromJson(Map<String, dynamic> json) {
    return VersionApiModel(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      time: DateTime.parse(json['time'] as String),
      releaseTime: DateTime.parse(json['releaseTime'] as String),
      complianceLevel: json['complianceLevel'] as int,
    );
  }
}
