import 'dart:ffi';
import 'dart:io';

import 'package:yelauncher/data/services/api/models/argument_api_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_api_model.dart';
import 'package:yelauncher/data/services/api/models/client_api_model.dart';
import 'package:yelauncher/data/services/api/models/library_api_model.dart';
import 'package:yelauncher/data/services/api/models/os_rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/utilities/result.dart';

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
            final model = LibraryApiModel(
              name: name,
              path: artifact['path'] as String,
              url: artifact['url'] as String,
              sha1: artifact['sha1'] as String? ?? '',
              size: artifact['size'] as int? ?? 0,
              rules: rules,
            );
            if (_isAllowed(model)) {
              libraries.add(model);
            }
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
              } else if (classifierName.contains('macos') ||
                  classifierName.contains('osx')) {
                osName = 'osx';
              }

              final classifierRules = rules?.toList() ?? [];
              // Standard Mojang libraries don't include rules for classifiers, they use "natives" map.
              // We should append a disallow for anything else, or just replace the rules completely
              // to restrict strictly to this OS since it's a native classifier.
              classifierRules.clear();
              classifierRules.add(
                RuleApiModel(
                  action: 'allow',
                  os: OsRuleApiModel(name: osName),
                ),
              );

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

  bool _isAllowed(LibraryApiModel model) {
    // Determine current system architecture
    final String currentArch = Abi.current().toString().contains('arm64')
        ? 'arm64'
        : (Abi.current().toString().contains('ia32') ||
                  Abi.current().toString().contains('x86')
              ? 'x86'
              : 'x64');

    // ==========================================
    // 1. ARCHITECTURE NAME HEURISTICS
    // ==========================================
    final lowerName = model.name.toLowerCase();
    final rules = model.rules;

    // Check if the library explicitly states it belongs to a specific architecture
    final bool isExplicitArm64 =
        lowerName.contains('arm64') || lowerName.contains('aarch64');
    final bool isExplicitX86 =
        lowerName.contains('x86') && !lowerName.contains('x86_64');
    final bool isExplicitX64 =
        lowerName.contains('x86_64') || lowerName.contains('x64');

    // In Minecraft (especially LWJGL), a generic "natives" jar without an arch
    // suffix (e.g., lwjgl-natives-windows.jar) is implicitly for 64-bit (x64) systems.
    final bool isImplicitX64Native =
        lowerName.contains('natives') &&
        !isExplicitArm64 &&
        !isExplicitX86 &&
        !isExplicitX64;

    if (currentArch == 'x64') {
      // If we are on 64-bit, explicitly reject ARM64 and 32-bit (x86) libraries
      if (isExplicitArm64 || isExplicitX86) return false;
    } else if (currentArch == 'arm64') {
      // If we are on ARM, reject x86, explicit x64, AND implicit x64 natives
      if (isExplicitX86 || isExplicitX64) return false;
      if (isImplicitX64Native &&
          (lowerName.contains('windows') || lowerName.contains('linux'))) {
        return false;
      }
    } else if (currentArch == 'x86') {
      // If we are on 32-bit, reject ARM and x64 libraries
      if (isExplicitArm64 || isExplicitX64) return false;
      if (isImplicitX64Native &&
          (lowerName.contains('windows') || lowerName.contains('linux'))) {
        return false;
      }
    }

    // ==========================================
    // 2. STANDARD JSON RULES EVALUATION
    // ==========================================
    if (rules == null || rules.isEmpty) return true;
    bool allowed = false;

    for (final rule in rules) {
      bool osMatch = true;
      bool archMatch = true;

      if (rule.os != null) {
        // Check OS
        if (rule.os!.name != null) {
          String currentOs = Platform.operatingSystem;
          if (currentOs == 'macos') currentOs = 'osx';
          if (rule.os!.name != currentOs) osMatch = false;
        }

        // Check Arch Rule (if the manifest actually provides one)
        if (rule.os!.arch != null && rule.os!.arch != currentArch) {
          archMatch = false;
        }
      }

      if (osMatch && archMatch) {
        allowed = (rule.action == 'allow');
      }
    }

    return allowed;
  }
}
