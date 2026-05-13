import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/api/models/argument_api_model.dart';
import 'package:yelauncher/data/services/api/strategies/version_requirements_strategy.dart';
import 'package:yelauncher/utilities/result.dart';

class Version21RequirementsStrategy extends VersionRequirementsStrategy {
  Version21RequirementsStrategy() : super(minimumLauncherVersion: 21);

  @override
  Result<VersionRequirementsApiModel> parseVersionPrerequisites(
    Map<String, dynamic> json,
  ) {
    try {
      List<ArgumentApiModel> arguments = [];
      if (json['arguments'] != null) {
        final argsMap = json['arguments'] as Map<String, dynamic>;
        for (final key in argsMap.keys) {
          final argsList = argsMap[key] as List<dynamic>;
          for (final item in argsList) {
            if (item is String) {
              arguments.add(ArgumentApiModel(values: [item], type: key));
            } else if (item is Map<String, dynamic>) {
              arguments.add(ArgumentApiModel.fromJson(item, type: key));
            }
          }
        }
      }

      return Result.success(parseCommon(json, arguments));
    } on FormatException catch (e) {
      return Result.failure(
        Exception('Failed to parse version requirements: $e'),
      );
    } catch (e) {
      return Result.failure(
        Exception('Failed to parse version requirements: $e'),
      );
    }
  }
}
