import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/data/services/api/models/asset_index_api_model.dart';
import 'package:yelauncher/data/services/api/models/client_api_model.dart';
import 'package:yelauncher/data/services/api/models/library_api_model.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/argument_api_model.dart';
import 'package:yelauncher/data/services/api/models/os_rule_api_model.dart';

abstract class VersionRequirementsStrategy {
  final int _minimumLauncherVersion;

  VersionRequirementsStrategy({required int minimumLauncherVersion})
    : _minimumLauncherVersion = minimumLauncherVersion;

  bool isCompatible(int launcherVersion) =>
      launcherVersion >= _minimumLauncherVersion;

  Result<VersionRequirementsApiModel> parseVersionPrerequisites(
    Map<String, dynamic> json,
  );

  VersionRequirementsApiModel parseCommon(
    Map<String, dynamic> json,
    List<ArgumentApiModel> arguments,
  ) {
    final assetIndexJson = json['assetIndex'] as Map<String, dynamic>;
    final assetIndex = AssetIndexApiModel.fromJson(assetIndexJson);

    final downloadsJson = json['downloads'] as Map<String, dynamic>;
    final clientJson = downloadsJson['client'] as Map<String, dynamic>;
    final client = ClientApiModel.fromJson(clientJson);

    final javaVersionJson = json['javaVersion'] as Map<String, dynamic>?;
    final javaVersion = javaVersionJson?['majorVersion']?.toString() ?? '8';

    final librariesList = json['libraries'] as List<dynamic>;
    final libraries = <LibraryApiModel>[];
    for (final lib in librariesList) {
      final libJson = lib as Map<String, dynamic>;
      final name = libJson['name'] as String;
      final downloads = libJson['downloads'] as Map<String, dynamic>?;
      
      List<RuleApiModel>? rules;
      if (libJson['rules'] != null) {
        final rulesList = libJson['rules'] as List<dynamic>;
        rules = rulesList
            .map((e) => RuleApiModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      if (downloads != null) {
        if (downloads['artifact'] != null) {
          final artifact = downloads['artifact'] as Map<String, dynamic>;
          // Ensure all required fields are present
          if (artifact['path'] != null && artifact['url'] != null) {
            libraries.add(
              LibraryApiModel(
                name: name,
                path: artifact['path'] as String,
                url: artifact['url'] as String,
                sha1: artifact['sha1'] as String? ?? '',
                size: artifact['size'] as int? ?? 0,
                rules: rules,
              ),
            );
          }
        }
        if (downloads['classifiers'] != null) {
          final classifiers = downloads['classifiers'] as Map<String, dynamic>;
          for (final entry in classifiers.entries) {
            final classifierName = entry.key; // e.g. "natives-windows"
            final artifact = entry.value as Map<String, dynamic>;
            if (artifact['path'] != null && artifact['url'] != null) {
              String osName = 'unknown';
              if (classifierName.contains('windows')) {
                osName = 'windows';
              } else if (classifierName.contains('linux')) {
                osName = 'linux';
              } else if (classifierName.contains('macos') || classifierName.contains('osx')) {
                osName = 'osx';
              }

              final classifierRules = rules?.toList() ?? [];
              classifierRules.add(RuleApiModel(action: 'allow', os: OsRuleApiModel(name: osName)));

              libraries.add(
                LibraryApiModel(
                  name: '$name:$classifierName',
                  path: artifact['path'] as String,
                  url: artifact['url'] as String,
                  sha1: artifact['sha1'] as String? ?? '',
                  size: artifact['size'] as int? ?? 0,
                  rules: classifierRules,
                  isNative: true,
                ),
              );
            }
          }
        }
      }
    }

    final mainClass = json['mainClass'] as String;

    return VersionRequirementsApiModel(
      arguments: arguments,
      assetIndex: assetIndex,
      client: client,
      javaVersion: javaVersion,
      libraries: libraries,
      mainClass: mainClass,
    );
  }
}
