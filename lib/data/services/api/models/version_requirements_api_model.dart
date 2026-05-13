import 'package:yelauncher/data/services/api/models/argument_api_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_api_model.dart';
import 'package:yelauncher/data/services/api/models/client_api_model.dart';
import 'package:yelauncher/data/services/api/models/library_api_model.dart';

class VersionRequirementsApiModel {
  final String id;
  final List<ArgumentApiModel> arguments;
  final AssetIndexApiModel assetIndex;
  final ClientApiModel client;
  final String javaVersion;
  final List<LibraryApiModel> libraries;
  final String mainClass;

  VersionRequirementsApiModel({
    required this.arguments,
    required this.assetIndex,
    required this.client,
    required this.javaVersion,
    required this.libraries,
    required this.mainClass,
    required this.id,
  });
}
