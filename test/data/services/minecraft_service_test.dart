import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yelauncher/data/services/minecraft_service.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_run_model.dart';
import 'package:yelauncher/utilities/result.dart';

void main() {
  late MinecraftService service;
  late Directory tempDir;
  late List<LogRecord> logs;
  late StreamSubscription<LogRecord> logSubscription;
  MinecraftProcessModel? currentProcess;

  setUp(() async {
    service = MinecraftService();
    tempDir = await Directory.systemTemp.createTemp('minecraft_service_test_');
    logs = [];
    logSubscription = Logger.root.onRecord.listen((record) {
      logs.add(record);
    });
  });

  tearDown(() async {
    if (currentProcess != null) {
      currentProcess!.kill();
      currentProcess = null;
    }
    await logSubscription.cancel();
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore deletion errors on Windows due to pending sink closures
      }
    }
  });

  group('MinecraftService.run', () {
    test('successfully launches process and logs output', () async {
      final gameDir = p.join(tempDir.path, 'game');
      
      final profile = MinecraftProfileModel(
        uuid: 'test-uuid',
        nickname: 'TestPlayer',
        accessToken: 'test-token',
        userType: 'mojang',
      );

      final runModel = MinecraftRunModel(
        javaExecutablePath: Platform.isWindows ? 'cmd.exe' : 'sh',
        gameDirectory: gameDir,
        clientJarPath: 'client.jar',
        libraryPaths: ['lib1.jar', 'lib2.jar'],
        nativeLibraryPaths: [],
        mainClass: 'net.minecraft.client.main.Main',
        jvmArguments: [
          '-Dtest.arg=1',
          '-cp',
          '\${classpath}',
        ],
        gameArguments: [
          '--username',
          '\${auth_player_name}',
          '--version',
          '\${version_name}',
          '--quickPlayPath',
          'somePath',
          '--demo',
          '', // empty arg should be filtered out
        ],
        nativesDirectory: 'natives',
        minecraftVersion: '1.20.4',
        assetsDirectory: 'assets',
        assetIndex: '1.20',
        libraryDirectory: 'libraries',
        profile: profile,
      );

      final result = await service.run(runModel);

      expect(result, isA<Success<MinecraftProcessModel>>());
      currentProcess = (result as Success<MinecraftProcessModel>).value;
      
      // Let it run for a tiny bit, then kill it to prevent hangs
      await Future.delayed(const Duration(milliseconds: 200));
      currentProcess!.kill();
      
      // We expect the log file to be created and populated
      final logFile = File(p.join(gameDir, 'logs', 'latest.log'));
      expect(await logFile.exists(), isTrue);
      
      // Give the stream a tiny bit of time to finish flushing to file
      await Future.delayed(const Duration(milliseconds: 100));
      
      final logContent = await logFile.readAsString();
      expect(logContent, contains('--- Launching Minecraft ---'));

      // Verify the arguments were constructed correctly by parsing the logs
      final launchLog = logs.firstWhere((l) => l.message.startsWith('Launching Minecraft with args:'));
      final argsString = launchLog.message.replaceFirst('Launching Minecraft with args: ', '');
      
      // Verify replacements
      expect(argsString, contains('-Xmx2G')); // Default memory
      expect(argsString, contains('-Dtest.arg=1')); // JVM arg
      expect(argsString, contains('net.minecraft.client.main.Main')); // Main class
      expect(argsString, contains('--username TestPlayer')); // Game arg replaced
      expect(argsString, contains('--version 1.20.4')); // Game arg replaced
      
      // Verify QuickPlay and demo filtering
      expect(argsString, isNot(contains('--quickPlayPath'))); // Should be filtered out
      expect(argsString, isNot(contains('somePath'))); // Should be filtered out
      expect(argsString, isNot(contains('--demo'))); // Should be filtered out
      
      // Verify classpath construction
      final expectedSeparator = Platform.isWindows ? ';' : ':';
      final expectedClasspath = 'lib1.jar${expectedSeparator}lib2.jar${expectedSeparator}client.jar';
      expect(argsString, contains(expectedClasspath));
    });

    test('adds classpath argument automatically if missing from jvm args', () async {
      final gameDir = p.join(tempDir.path, 'game');
      
      final profile = MinecraftProfileModel(
        uuid: 'test-uuid',
        nickname: 'TestPlayer',
        accessToken: 'test-token',
        userType: 'mojang',
      );

      final runModel = MinecraftRunModel(
        javaExecutablePath: Platform.isWindows ? 'cmd.exe' : 'sh',
        gameDirectory: gameDir,
        clientJarPath: 'client.jar',
        libraryPaths: ['lib1.jar'],
        nativeLibraryPaths: [],
        mainClass: 'net.minecraft.client.main.Main',
        jvmArguments: [
          '-Dsome.arg=true', // NO classpath variable here
        ],
        gameArguments: [],
        nativesDirectory: 'natives',
        minecraftVersion: '1.20.4',
        assetsDirectory: 'assets',
        assetIndex: '1.20',
        libraryDirectory: 'libraries',
        profile: profile,
      );

      final result = await service.run(runModel);
      
      expect(result, isA<Success<MinecraftProcessModel>>());
      currentProcess = (result as Success<MinecraftProcessModel>).value;

      final launchLog = logs.firstWhere((l) => l.message.startsWith('Launching Minecraft with args:'));
      final argsString = launchLog.message;
      
      expect(argsString, contains('-Djava.library.path=natives'));
      expect(argsString, contains('-cp'));
      
      final expectedSeparator = Platform.isWindows ? ';' : ':';
      expect(argsString, contains('lib1.jar${expectedSeparator}client.jar'));
    });

    test('returns failure if executable is missing or invalid', () async {
      final gameDir = p.join(tempDir.path, 'game');
      
      final profile = MinecraftProfileModel(
        uuid: 'test-uuid',
        nickname: 'TestPlayer',
        accessToken: 'test-token',
        userType: 'mojang',
      );

      final runModel = MinecraftRunModel(
        javaExecutablePath: 'non_existent_executable_path_123',
        gameDirectory: gameDir,
        clientJarPath: 'client.jar',
        libraryPaths: [],
        nativeLibraryPaths: [],
        mainClass: 'Main',
        jvmArguments: [],
        gameArguments: [],
        nativesDirectory: 'natives',
        minecraftVersion: '1.20.4',
        assetsDirectory: 'assets',
        assetIndex: '1.20',
        libraryDirectory: 'libraries',
        profile: profile,
      );

      final result = await service.run(runModel);

      expect(result, isA<Failure>());
      final failure = result as Failure;
      expect(failure.error, isA<ProcessException>());
    });
  });
}
