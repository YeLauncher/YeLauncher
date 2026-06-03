import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/utilities/result.dart';

/// Service responsible for launching Minecraft instances.
///
/// This extracts the launch / run logic out of the repository layer so that
/// [InstanceRepository] stays a pure data-persistence contract.
class InstanceService {
  final _log = Logger('InstanceService');
  final MinecraftApiClient _apiClient;
  final JavaRepository _javaRepository;
  
  final Map<String, Process> _runningProcesses = {};

  InstanceService({
    required MinecraftApiClient apiClient,
    required JavaRepository javaRepository,
  })  : _apiClient = apiClient,
        _javaRepository = javaRepository;

  /// Launches the Minecraft process for the given [instance].
  Future<void> run(InstanceModel instance) async {
    if (isRunning(instance.id)) return;

    final versionResult =
        await _apiClient.getVersion(instance.minecraftVersion);
    switch (versionResult) {
      case Success<VersionApiModel>():
        final reqResult =
            await _apiClient.getRequirements(versionResult.value);
        switch (reqResult) {
          case Success<VersionRequirementsApiModel>():
            int javaVersion = int.tryParse(reqResult.value.javaVersion) ?? 17;
            final javaIsInstalled = await _javaRepository.isInstalled(javaVersion);
            if (javaIsInstalled case Success<bool>(value: false)) {
              final installResult = await _javaRepository.install(javaVersion);
              if (installResult is Failure) {
                _log.severe('Failed to install Java: ${installResult.error}');
                return;
              }
            }
            final javaExecPathResult = await _javaRepository.getJavaExecutablePath(javaVersion);
            switch (javaExecPathResult) {
              case Success<String>():
                await _launch(instance, reqResult.value, javaExecPathResult.value);
                break;
              case Failure<String>():
                _log.severe('Failed to get Java path: ${javaExecPathResult.error}');
                return;
            }
            break;
          case Failure<VersionRequirementsApiModel>():
            _log.severe('Failed to get requirements: ${reqResult.error}');
            break;
        }
        break;
      case Failure<VersionApiModel>():
        _log.severe('Failed to get version: ${versionResult.error}');
        break;
    }
  }

  Future<void> _launch(
    InstanceModel instance,
    VersionRequirementsApiModel requirements,
    String javaExecutablePath,
  ) async {
    final appData = await getApplicationSupportDirectory();
    final gameDir = appData.path;
    final assetsDir = p.join(gameDir, 'assets');

    final cp = <String>[];
    final nativeJarPaths = <String>[];
    for (final lib in requirements.libraries) {
      if (!_isAllowed(lib.rules)) continue;

      if (lib.path.isNotEmpty) {
        final libPath = p.join(gameDir, 'libraries', lib.path);
        if (lib.isNative) {
          nativeJarPaths.add(libPath);
        } else {
          cp.add(libPath);
        }
      }
    }
    cp.add(p.join(
      gameDir,
      'versions',
      instance.minecraftVersion,
      '${instance.minecraftVersion}.jar',
    ));

    // Extract native libraries from native JARs into the natives directory.
    final nativesDir = Directory(p.join(gameDir, 'natives'));
    if (!await nativesDir.exists()) {
      await nativesDir.create(recursive: true);
    }
    for (final jarPath in nativeJarPaths) {
      final jarFile = File(jarPath);
      if (!await jarFile.exists()) {
        _log.warning('Native JAR not found: $jarPath');
        continue;
      }
      _log.info('Extracting natives from: $jarPath');
      final bytes = await jarFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile) {
          final name = file.name.toLowerCase();
          if (name.endsWith('.dll') ||
              name.endsWith('.so') ||
              name.endsWith('.dylib') ||
              name.endsWith('.jnilib')) {
            final outFile =
                File(p.join(nativesDir.path, p.basename(file.name)));
            await outFile.writeAsBytes(file.content as List<int>);
            _log.fine('Extracted: ${p.basename(file.name)}');
          }
        }
      }
    }

    final classpath = cp.join(Platform.isWindows ? ';' : ':');

    final jvmArgs = <String>[];
    final gameArgs = <String>[];

    for (final arg in requirements.arguments) {
      if (!_isAllowed(arg.rules)) continue;

      for (final val in arg.values) {
        final replaced = val
            .replaceAll('\${auth_player_name}', 'Player')
            .replaceAll('\${version_name}', instance.minecraftVersion)
            .replaceAll('\${game_directory}', gameDir)
            .replaceAll('\${assets_root}', assetsDir)
            .replaceAll('\${assets_index_name}', requirements.assetIndex.id)
            .replaceAll(
              '\${auth_uuid}',
              '00000000-0000-0000-0000-000000000000',
            )
            .replaceAll('\${auth_access_token}', '0')
            .replaceAll('\${clientid}', '')
            .replaceAll('\${auth_xuid}', '')
            .replaceAll('\${user_type}', 'mojang')
            .replaceAll('\${user_properties}', '{}')
            .replaceAll('\${version_type}', 'release')
            .replaceAll('\${resolution_width}', '854')
            .replaceAll('\${resolution_height}', '480')
            .replaceAll('\${natives_directory}', p.join(gameDir, 'natives'))
            .replaceAll('\${launcher_name}', 'yelauncher')
            .replaceAll('\${launcher_version}', '1.0.0')
            .replaceAll('\${classpath}', classpath)
            .replaceAll('\${path}', p.join(gameDir, 'natives'))
            .replaceAll('\${quickPlayPath}', '')
            .replaceAll('\${quickPlayMultiplayer}', '')
            .replaceAll('\${quickPlayRealms}', '')
            .replaceAll('\${quickPlaySingleplayer}', '')
            .replaceAll('\${library_directory}', p.join(gameDir, 'libraries'))
            .replaceAll(
              '\${classpath_separator}',
              Platform.isWindows ? ';' : ':',
            );

        if (replaced == '--sun-misc-unsafe-memory-access=allow') {
          continue; // Strip unsupported JVM arg that causes startup failures on older JREs
        }

        if (arg.type == 'jvm') {
          jvmArgs.add(replaced);
        } else {
          gameArgs.add(replaced);
        }
      }
    }

    if (jvmArgs.isEmpty) {
      jvmArgs.add('-Djava.library.path=${p.join(gameDir, "natives")}');
      jvmArgs.add('-cp');
      jvmArgs.add(classpath);
    }

    final finalArgs = <String>[
      '-Xmx2G',
      ...jvmArgs,
      requirements.mainClass,
      ...gameArgs,
    ];

    _log.info('Starting Minecraft with Java ($javaExecutablePath) using args: $finalArgs');
    final process =
        await Process.start(javaExecutablePath, finalArgs, workingDirectory: gameDir);
        
    _runningProcesses[instance.id] = process;
    
    process.stdout
        .transform(utf8.decoder)
        .listen((data) => _log.info('MC_STDOUT: $data'));
    process.stderr
        .transform(utf8.decoder)
        .listen((data) => _log.severe('MC_STDERR: $data'));

    process.exitCode.then((code) {
      _log.info('Minecraft process exited with code $code');
      _runningProcesses.remove(instance.id);
    });
  }

  /// Stops a running Minecraft instance
  void stop(InstanceModel instance) {
    final process = _runningProcesses[instance.id];
    if (process != null) {
      _log.info('Killing process for instance ${instance.id}');
      process.kill();
      _runningProcesses.remove(instance.id);
    }
  }

  /// Checks if a Minecraft instance is currently running
  bool isRunning(String instanceId) {
    return _runningProcesses.containsKey(instanceId);
  }

  /// Opens the folder containing the instance
  Future<void> openFolder(InstanceModel instance) async {
    final appData = await getApplicationSupportDirectory();
    final gameDir = appData.path; // Game dir is shared for now
    
    _log.info('Opening folder: $gameDir');
    
    if (Platform.isWindows) {
      await Process.start('explorer', [gameDir]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [gameDir]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [gameDir]);
    }
  }

  /// Evaluates Mojang-style OS rules.
  bool _isAllowed(List<RuleApiModel>? rules) {
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
}
