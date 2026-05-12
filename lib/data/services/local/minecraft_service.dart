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

      // Extract native libraries from native JARs into the natives directory.
      // final nativesDir = Directory(p.join(gameDir, 'natives'));
      // if (!await nativesDir.exists()) {
      //   await nativesDir.create(recursive: true);
      // }
      // for (final jarPath in nativeJarPaths) {
      //   final jarFile = File(jarPath);
      //   if (!await jarFile.exists()) {
      //     _log.warning('Native JAR not found: $jarPath');
      //     continue;
      //   }
      //   _log.info('Extracting natives from: $jarPath');
      //   final bytes = await jarFile.readAsBytes();
      //   final archive = ZipDecoder().decodeBytes(bytes);
      //   for (final file in archive) {
      //     if (file.isFile) {
      //       final name = file.name.toLowerCase();
      //       if (name.endsWith('.dll') ||
      //           name.endsWith('.so') ||
      //           name.endsWith('.dylib') ||
      //           name.endsWith('.jnilib')) {
      //         final outFile = File(
      //           p.join(nativesDir.path, p.basename(file.name)),
      //         );
      //         await outFile.writeAsBytes(file.content as List<int>);
      //         _log.fine('Extracted: ${p.basename(file.name)}');
      //       }
      //     }
      //   }
      // }

      final classpath = cp.join(Platform.isWindows ? ';' : ':');

      final jvmArgs = <String>[];

      // for (final arg in requirements.arguments) {
      //   if (!_isAllowed(arg.rules)) continue;

      //   for (final val in arg.values) {
      //     final replaced = val
      //         .replaceAll('\${auth_player_name}', 'Player')
      //         .replaceAll('\${version_name}', instance.minecraftVersion)
      //         .replaceAll('\${game_directory}', gameDir)
      //         .replaceAll('\${assets_root}', assetsDir)
      //         .replaceAll('\${assets_index_name}', requirements.assetIndex.id)
      //         .replaceAll('\${auth_uuid}', '00000000-0000-0000-0000-000000000000')
      //         .replaceAll('\${auth_access_token}', '0')
      //         .replaceAll('\${clientid}', '')
      //         .replaceAll('\${auth_xuid}', '')
      //         .replaceAll('\${user_type}', 'mojang')
      //         .replaceAll('\${user_properties}', '{}')
      //         .replaceAll('\${version_type}', 'release')
      //         .replaceAll('\${resolution_width}', '854')
      //         .replaceAll('\${resolution_height}', '480')
      //         .replaceAll('\${natives_directory}', p.join(gameDir, 'natives'))
      //         .replaceAll('\${launcher_name}', 'yelauncher')
      //         .replaceAll('\${launcher_version}', '1.0.0')
      //         .replaceAll('\${classpath}', classpath)
      //         .replaceAll('\${path}', p.join(gameDir, 'natives'))
      //         .replaceAll('\${quickPlayPath}', '')
      //         .replaceAll('\${quickPlayMultiplayer}', '')
      //         .replaceAll('\${quickPlayRealms}', '')
      //         .replaceAll('\${quickPlaySingleplayer}', '')
      //         .replaceAll('\${library_directory}', p.join(gameDir, 'libraries'))
      //         .replaceAll(
      //           '\${classpath_separator}',
      //           Platform.isWindows ? ';' : ':',
      //         );

      //     if (replaced == '--sun-misc-unsafe-memory-access=allow') {
      //       continue; // Strip unsupported JVM arg that causes startup failures on older JREs
      //     }

      //     if (arg.type == 'jvm') {
      //       jvmArgs.add(replaced);
      //     } else {
      //       gameArgs.add(replaced);
      //     }
      //   }
      // }

      if (model.jvmArguments.isEmpty) {
        jvmArgs.add('-cp');
        jvmArgs.add(classpath);
      }

      final finalArgs = <String>[
        '-Xmx2G',
        ...jvmArgs,
        model.mainClass,
        ...model.gameArguments,
      ];
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
}
