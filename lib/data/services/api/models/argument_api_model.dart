import 'package:yelauncher/data/services/api/models/rule_api_model.dart';

class ArgumentApiModel {
  final List<String> values;
  final List<RuleApiModel>? rules;
  final String type;

  const ArgumentApiModel({
    required this.values,
    this.rules,
    this.type = 'game',
  });

  factory ArgumentApiModel.fromJson(Map<String, dynamic> json, {String type = 'game'}) {
    List<String> values = [];
    if (json['value'] is String) {
      values.add(json['value'] as String);
    } else if (json['value'] is List) {
      values.addAll((json['value'] as List).cast<String>());
    }

    List<RuleApiModel>? rules;
    if (json['rules'] != null) {
      rules = (json['rules'] as List)
          .map((e) => RuleApiModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ArgumentApiModel(
      values: values,
      rules: rules,
      type: type,
    );
  }
}
