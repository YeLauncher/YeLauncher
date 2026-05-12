import 'package:yelauncher/data/services/api/models/rule_api_model.dart';

class LibraryApiModel {
  final String name;
  final String path;
  final String url;
  final String sha1;
  final int size;
  final List<RuleApiModel>? rules;
  final bool isNative;

  LibraryApiModel({
    required this.name,
    required this.path,
    required this.url,
    required this.sha1,
    required this.size,
    this.rules,
    this.isNative = false,
  });
}
