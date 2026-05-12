import 'package:yelauncher/data/services/api/models/latest_versions_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_api_model.dart';

class VersionManifestApiModel {
  final List<VersionApiModel> versions;
  final LatestVersionsApiModel latest;

  VersionManifestApiModel({required this.versions, required this.latest});

  factory VersionManifestApiModel.fromJson(Map<String, dynamic> json) {
    return VersionManifestApiModel(
      versions:
          (json['versions'] as List<dynamic>?)
              ?.map((e) => VersionApiModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      latest: LatestVersionsApiModel.fromJson(
        json['latest'] as Map<String, dynamic>,
      ),
    );
  }
}
