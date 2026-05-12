import 'package:yelauncher/data/services/api/models/os_rule_api_model.dart';

class RuleApiModel {
  final String action;
  final OsRuleApiModel? os;
  final Map<String, bool>? features;

  const RuleApiModel({
    required this.action,
    this.os,
    this.features,
  });

  factory RuleApiModel.fromJson(Map<String, dynamic> json) {
    Map<String, bool>? parsedFeatures;
    if (json['features'] != null) {
      final featuresMap = json['features'] as Map<String, dynamic>;
      parsedFeatures = featuresMap.map((key, value) => MapEntry(key, value as bool));
    }

    return RuleApiModel(
      action: json['action'] as String,
      os: json['os'] != null ? OsRuleApiModel.fromJson(json['os'] as Map<String, dynamic>) : null,
      features: parsedFeatures,
    );
  }
}
