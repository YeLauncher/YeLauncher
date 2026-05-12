import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/utilities/result.dart';

/// Builds the full list of Java launch arguments the same way
/// [InstanceRepositoryDevelopment.run] does, so we can verify the pipeline
/// end-to-end without actually starting a JVM process.
List<String> buildLaunchArgs({
  required VersionRequirementsApiModel requirements,
  required String versionId,
  required String gameDir,
}) {
  final assetsDir = '$gameDir/assets';

  bool isAllowed(List<RuleApiModel>? rules) {
    if (rules == null || rules.isEmpty) return true;
    bool allowed = false;
    for (final rule in rules) {
      bool osMatch = true;
      if (rule.os != null && rule.os!.name != null) {
        String currentOs = Platform.operatingSystem;
        if (currentOs == 'macos') currentOs = 'osx';
        osMatch = (rule.os!.name == currentOs);
      }
      if (osMatch) {
        allowed = (rule.action == 'allow');
      }
    }
    return allowed;
  }

  final cp = <String>[];
  for (final lib in requirements.libraries) {
    if (!isAllowed(lib.rules)) continue;
    if (lib.path.isNotEmpty) {
      cp.add('$gameDir/libraries/${lib.path}');
    }
  }
  cp.add('$gameDir/versions/$versionId/$versionId.jar');

  final classpath = cp.join(Platform.isWindows ? ';' : ':');

  final jvmArgs = <String>[];
  final gameArgs = <String>[];

  for (final arg in requirements.arguments) {
    if (!isAllowed(arg.rules)) continue;

    for (final val in arg.values) {
      final replaced = val
          .replaceAll('\${auth_player_name}', 'Player')
          .replaceAll('\${version_name}', versionId)
          .replaceAll('\${game_directory}', gameDir)
          .replaceAll('\${assets_root}', assetsDir)
          .replaceAll('\${assets_index_name}', requirements.assetIndex.id)
          .replaceAll('\${auth_uuid}', '00000000-0000-0000-0000-000000000000')
          .replaceAll('\${auth_access_token}', '0')
          .replaceAll('\${clientid}', '')
          .replaceAll('\${auth_xuid}', '')
          .replaceAll('\${user_type}', 'mojang')
          .replaceAll('\${user_properties}', '{}')
          .replaceAll('\${version_type}', 'release')
          .replaceAll('\${resolution_width}', '854')
          .replaceAll('\${resolution_height}', '480')
          .replaceAll('\${natives_directory}', '$gameDir/natives')
          .replaceAll('\${launcher_name}', 'yelauncher')
          .replaceAll('\${launcher_version}', '1.0.0')
          .replaceAll('\${classpath}', classpath)
          .replaceAll('\${path}', '$gameDir/natives')
          .replaceAll('\${quickPlayPath}', '')
          .replaceAll('\${quickPlayMultiplayer}', '')
          .replaceAll('\${quickPlayRealms}', '')
          .replaceAll('\${quickPlaySingleplayer}', '')
          .replaceAll('\${library_directory}', '$gameDir/libraries')
          .replaceAll('\${classpath_separator}', Platform.isWindows ? ';' : ':');

      if (arg.type == 'jvm') {
        jvmArgs.add(replaced);
      } else {
        gameArgs.add(replaced);
      }
    }
  }

  if (jvmArgs.isEmpty) {
    jvmArgs.add('-Djava.library.path=$gameDir/natives');
    jvmArgs.add('-cp');
    jvmArgs.add(classpath);
  }

  return <String>['-Xmx2G', ...jvmArgs, requirements.mainClass, ...gameArgs];
}

void main() {
  const manifestUrl =
      'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json';
  late MinecraftApiClient apiClient;

  setUp(() {
    apiClient = MinecraftApiClient(baseUrl: manifestUrl);
  });

  // ---------------------------------------------------------------
  // Helper: load & parse requirements for a given version id.
  // Returns the parsed VersionRequirementsApiModel or fails the test.
  // ---------------------------------------------------------------
  Future<VersionRequirementsApiModel> loadRequirements(String versionId) async {
    final versionResult = await apiClient.getVersion(versionId);
    expect(versionResult, isA<Success<VersionApiModel>>());
    final version = (versionResult as Success<VersionApiModel>).value;
    expect(version.id, versionId);

    final reqResult = await apiClient.getRequirements(version);
    expect(reqResult, isA<Success<VersionRequirementsApiModel>>());
    return (reqResult as Success<VersionRequirementsApiModel>).value;
  }

  // ---------------------------------------------------------------
  // Shared assertions for requirements & launch args
  // ---------------------------------------------------------------
  void verifyRequirements(VersionRequirementsApiModel req) {
    expect(req.mainClass, isNotEmpty);
    expect(req.libraries, isNotEmpty);
    expect(req.assetIndex.id, isNotEmpty);
    expect(req.assetIndex.url, startsWith('https://'));
    expect(req.client.url, startsWith('https://'));
    expect(req.client.sha1, isNotEmpty);
    expect(req.client.size, greaterThan(0));
    expect(req.javaVersion, isNotEmpty);
  }

  void verifyLaunchArgs(
    List<String> args,
    VersionRequirementsApiModel req,
    String versionId,
  ) {
    // Must start with -Xmx2G
    expect(args.first, '-Xmx2G');

    // Must contain mainClass
    expect(args, contains(req.mainClass));

    // The classpath must reference the client jar
    final cpSegment = args
        .where((a) => a.contains('$versionId/$versionId.jar'))
        .toList();
    expect(cpSegment, isNotEmpty,
        reason: 'Classpath must reference $versionId.jar');

    // No unresolved placeholders should remain
    for (final arg in args) {
      expect(arg, isNot(contains('\${')),
          reason: 'Unresolved placeholder found: $arg');
    }

    // The mainClass must appear after all JVM args and before game args
    final mainClassIdx = args.indexOf(req.mainClass);
    expect(mainClassIdx, greaterThan(0),
        reason: 'mainClass must not be the first argument');

    // Everything before mainClass should be JVM flags (starting with -)
    // or a classpath string. At minimum, -Xmx2G is there.
    expect(args[0], startsWith('-'));
  }

  // ==================================================================
  // Version 1.8.9  (minimumLauncherVersion ~14, parsed by Version4)
  // ==================================================================
  group('Minecraft 1.8.9', () {
    test('loading: fetches and parses version requirements', () async {
      final req = await loadRequirements('1.8.9');
      verifyRequirements(req);

      // v4 strategy — arguments come from minecraftArguments as plain strings,
      // all with type 'game', no JVM args from the manifest.
      expect(req.mainClass, 'net.minecraft.client.main.Main');
      expect(req.arguments.where((a) => a.type == 'game'), isNotEmpty);
    });

    test('launching: constructs valid launch arguments', () async {
      final req = await loadRequirements('1.8.9');
      final args =
          buildLaunchArgs(requirements: req, versionId: '1.8.9', gameDir: 'C:/game');
      verifyLaunchArgs(args, req, '1.8.9');

      // v4 falls back to default JVM args
      expect(args, contains('-Djava.library.path=C:/game/natives'));
    });
  });

  // ==================================================================
  // Version 1.12.2  (minimumLauncherVersion ~18, parsed by Version4)
  // ==================================================================
  group('Minecraft 1.12.2', () {
    test('loading: fetches and parses version requirements', () async {
      final req = await loadRequirements('1.12.2');
      verifyRequirements(req);

      expect(req.mainClass, 'net.minecraft.client.main.Main');
      expect(req.arguments.where((a) => a.type == 'game'), isNotEmpty);
    });

    test('launching: constructs valid launch arguments', () async {
      final req = await loadRequirements('1.12.2');
      final args =
          buildLaunchArgs(requirements: req, versionId: '1.12.2', gameDir: 'C:/game');
      verifyLaunchArgs(args, req, '1.12.2');

      // v4 falls back to default JVM args
      expect(args, contains('-Djava.library.path=C:/game/natives'));
    });
  });

  // ==================================================================
  // Version 1.16.5  (minimumLauncherVersion 21, parsed by Version21)
  // ==================================================================
  group('Minecraft 1.16.5', () {
    test('loading: fetches and parses version requirements', () async {
      final req = await loadRequirements('1.16.5');
      verifyRequirements(req);

      // Since 1.13 the main class is net.minecraft.client.main.Main
      expect(req.mainClass, 'net.minecraft.client.main.Main');
      // v21 strategy — has both JVM and game arguments
      expect(req.arguments.where((a) => a.type == 'jvm'), isNotEmpty);
      expect(req.arguments.where((a) => a.type == 'game'), isNotEmpty);
    });

    test('launching: constructs valid launch arguments', () async {
      final req = await loadRequirements('1.16.5');
      final args =
          buildLaunchArgs(requirements: req, versionId: '1.16.5', gameDir: 'C:/game');
      verifyLaunchArgs(args, req, '1.16.5');

      // v21 provides JVM args from the manifest — native library path
      // is resolved from ${natives_directory} in the JVM args template.
      expect(args.any((a) => a.contains('java.library.path')), isTrue);
    });
  });

  // ==================================================================
  // Version 1.18.2  (minimumLauncherVersion 21, parsed by Version21)
  // ==================================================================
  group('Minecraft 1.18.2', () {
    test('loading: fetches and parses version requirements', () async {
      final req = await loadRequirements('1.18.2');
      verifyRequirements(req);

      expect(req.mainClass, 'net.minecraft.client.main.Main');
      expect(req.arguments.where((a) => a.type == 'jvm'), isNotEmpty);
      expect(req.arguments.where((a) => a.type == 'game'), isNotEmpty);
      // 1.18.2 requires Java 17
      expect(req.javaVersion, '17');
    });

    test('launching: constructs valid launch arguments', () async {
      final req = await loadRequirements('1.18.2');
      final args =
          buildLaunchArgs(requirements: req, versionId: '1.18.2', gameDir: 'C:/game');
      verifyLaunchArgs(args, req, '1.18.2');
    });
  });

  // ==================================================================
  // Version 1.21.1  (minimumLauncherVersion 21, parsed by Version21)
  // ==================================================================
  group('Minecraft 1.21.1', () {
    test('loading: fetches and parses version requirements', () async {
      final req = await loadRequirements('1.21.1');
      verifyRequirements(req);

      expect(req.mainClass, 'net.minecraft.client.main.Main');
      expect(req.arguments.where((a) => a.type == 'jvm'), isNotEmpty);
      expect(req.arguments.where((a) => a.type == 'game'), isNotEmpty);
      // 1.21.1 requires Java 21
      expect(req.javaVersion, '21');
    });

    test('launching: constructs valid launch arguments', () async {
      final req = await loadRequirements('1.21.1');
      final args =
          buildLaunchArgs(requirements: req, versionId: '1.21.1', gameDir: 'C:/game');
      verifyLaunchArgs(args, req, '1.21.1');
    });
  });

  // ==================================================================
  // Version 26.1  (minimumLauncherVersion 21, parsed by Version21)
  // ==================================================================
  group('Minecraft 26.1', () {
    test('loading: fetches and parses version requirements', () async {
      final req = await loadRequirements('26.1');
      verifyRequirements(req);

      expect(req.arguments.where((a) => a.type == 'jvm'), isNotEmpty);
      expect(req.arguments.where((a) => a.type == 'game'), isNotEmpty);
    });

    test('launching: constructs valid launch arguments', () async {
      final req = await loadRequirements('26.1');
      final args =
          buildLaunchArgs(requirements: req, versionId: '26.1', gameDir: 'C:/game');
      verifyLaunchArgs(args, req, '26.1');
    });
  });
}
