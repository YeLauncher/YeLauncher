import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_run_model.dart';
import 'package:yelauncher/utilities/result.dart';

class MinecraftService {
  final _log = Logger('MinecraftService');

  Future<Result<void>> run(MinecraftRunModel model) async {
    try {
      final cp = <String>[];
      for (final libPath in model.libraryPaths) {
        cp.add(libPath);
      }
      cp.add(model.clientJarPath);

      final classpath = cp.join(Platform.isWindows ? ';' : ':');

      final jvmArgs = <String>[];

      if (model.jvmArguments.isEmpty) {
        jvmArgs.add('-cp');
        jvmArgs.add(classpath);
      } else {
        jvmArgs.addAll(model.jvmArguments);
      }

      final finalArgs = await _replaceArgs(
        <String>[
          '-Xmx2G',
          ...jvmArgs,
          model.mainClass,
          ...model.gameArguments,
        ].where((arg) => _isSupportedArgument(arg)).toList(),
        model,
        classpath,
      );

      // We need to create the gameDirectory to avoid launch errors when it doesn't exist
      final workingDir = Directory(model.gameDirectory);
      if (!await workingDir.exists()) {
        await workingDir.create(recursive: true);
      }

      _log.fine("Launching Minecraft with args: ${finalArgs.join(' ')}");
      final process = await Process.start(
        model.javaExecutablePath,
        finalArgs,
        workingDirectory: model.gameDirectory,
      );

      process.stdout
          .transform(utf8.decoder)
          .listen((data) => _log.info('Minecraft: $data'));
      process.stderr
          .transform(utf8.decoder)
          .listen((data) => _log.severe('Minecraft: $data'));

      process.exitCode.then((code) {
        _log.info('Minecraft process exited with code $code');
      });
      return Result.success(null);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  Future<List<String>> _replaceArgs(
    List<String> args,
    MinecraftRunModel model,
    String classpath,
  ) async {
    List<String> finalArgs = [];
    for (var value in args) {
      finalArgs.add(
        value
            .replaceAll('\${auth_player_name}', 'Player')
            .replaceAll('\${version_name}', model.minecraftVersion)
            .replaceAll('\${game_directory}', model.gameDirectory)
            .replaceAll('\${assets_root}', model.assetsDirectory)
            .replaceAll('\${assets_index_name}', model.assetIndex)
            .replaceAll('\${auth_uuid}', '00000000-0000-0000-0000-000000000000')
            .replaceAll('\${auth_access_token}', '0')
            .replaceAll('\${clientid}', 'test')
            .replaceAll('\${auth_xuid}', 'test')
            .replaceAll('\${user_type}', 'mojang')
            .replaceAll('\${user_properties}', '{}')
            .replaceAll('\${version_type}', 'release')
            .replaceAll('\${resolution_width}', '854')
            .replaceAll('\${resolution_height}', '480')
            .replaceAll('\${natives_directory}', model.nativesDirectory)
            .replaceAll('\${launcher_name}', 'yelauncher')
            .replaceAll('\${launcher_version}', '1.0.0')
            .replaceAll('\${classpath}', classpath)
            .replaceAll('\${path}', model.nativesDirectory)
            .replaceAll('\${library_directory}', model.libraryDirectory)
            .replaceAll(
              '\${classpath_separator}',
              Platform.isWindows ? ';' : ':',
            ),
      );
    }
    return finalArgs;
  }

  bool _isSupportedArgument(String arg) {
    return arg != '\${quickPlayPath}' &&
        arg != '\${quickPlayMultiplayer}' &&
        arg != '\${quickPlayRealms}' &&
        arg != '\${quickPlaySingleplayer}' &&
        arg != '--quickPlayRealms' &&
        arg != '--quickPlayMultiplayer' &&
        arg != '--quickPlaySingleplayer' &&
        arg != '--quickPlayPath' &&
        arg != '--demo';
  }
}
