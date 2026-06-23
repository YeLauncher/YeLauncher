import 'package:yelauncher/data/services/api/models/version_range_api_model.dart';

class OsRuleApiModel {
  final String? name;
  final String? version;
  final String? arch;
  final VersionRangeApiModel? versionRange;

  const OsRuleApiModel({this.name, this.version, this.arch, this.versionRange});

  factory OsRuleApiModel.fromJson(Map<String, dynamic> json) {
    return OsRuleApiModel(
      name: json['name'] as String?,
      version: json['version'] as String?,
      arch: json['arch'] as String?,
      versionRange: json['versionRange'] != null
          ? VersionRangeApiModel.fromJson(
              json['versionRange'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
