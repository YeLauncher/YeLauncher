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
        jvmArgs.add('-Djava.library.path=${model.nativesDirectory}');
        jvmArgs.add('-cp');
        jvmArgs.add(classpath);
      } else {
        jvmArgs.addAll(model.jvmArguments);
      }

      final originalArgs = <String>[
        '-Xmx2G',
        ...jvmArgs,
        model.mainClass,
        ...model.gameArguments,
      ];

      final filteredArgs = <String>[];
      for (int i = 0; i < originalArgs.length; i++) {
        final arg = originalArgs[i];
        // If it's a quickplay flag, skip it and its following argument (the value)
        if (arg == '--quickPlayPath' ||
            arg == '--quickPlaySingleplayer' ||
            arg == '--quickPlayMultiplayer' ||
            arg == '--quickPlayRealms') {
          // check if next argument is a variable for this flag
          if (i + 1 < originalArgs.length && originalArgs[i + 1].startsWith('\${quickPlay')) {
            i++;
          }
          continue;
        }
        if (arg.contains('\${quickPlay') || arg == '--demo') {
          continue;
        }
        filteredArgs.add(arg);
      }

      final finalArgs = await _replaceArgs(
        filteredArgs,
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
            .replaceAll('\${auth_player_name}', model.profile.nickname)
            .replaceAll('\${version_name}', model.minecraftVersion)
            .replaceAll('\${game_directory}', model.gameDirectory)
            .replaceAll('\${assets_root}', model.assetsDirectory)
            .replaceAll('\${assets_index_name}', model.assetIndex)
            .replaceAll('\${auth_uuid}', model.profile.uuid)
            .replaceAll('\${auth_access_token}', model.profile.accessToken)
            .replaceAll('\${clientid}', 'yelauncher')
            .replaceAll('\${auth_xuid}', '0')
            .replaceAll('\${user_type}', model.profile.userType)
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
}
