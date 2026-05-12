class VersionRangeApiModel {
  final String? min;
  final String? max;

  const VersionRangeApiModel({
    this.min,
    this.max,
  });

  factory VersionRangeApiModel.fromJson(Map<String, dynamic> json) {
    return VersionRangeApiModel(
      min: json['min'] as String?,
      max: json['max'] as String?,
    );
  }
}
