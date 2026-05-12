import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/api/models/argument_api_model.dart';
import 'package:yelauncher/data/services/api/strategies/version_requirements_strategy.dart';
import 'package:yelauncher/utilities/result.dart';

class Version4RequirementsStrategy extends VersionRequirementsStrategy {
  Version4RequirementsStrategy() : super(minimumLauncherVersion: 4);

  @override
  Result<VersionRequirementsApiModel> parseVersionPrerequisites(
    Map<String, dynamic> json,
  ) {
    try {
      List<ArgumentApiModel> arguments = [];
      if (json['minecraftArguments'] != null) {
        final argsString = json['minecraftArguments'] as String;
        final argsList = argsString.split(' ');
        arguments = argsList.map((e) => ArgumentApiModel(values: [e])).toList();
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
