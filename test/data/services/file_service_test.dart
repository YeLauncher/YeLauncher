import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:yelauncher/data/services/file_service.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;

  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  late FileService service;
  late Directory tempDir;

  setUp(() async {
    service = FileService();
    tempDir = await Directory.systemTemp.createTemp('file_service_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileService path getters', () {
    test('getLibraryDirectory - standard call - returns expected absolute path', () async {
      // Act
      final result = await service.getLibraryDirectory();

      // Assert
      final expectedPath = p.join(tempDir.path, 'libraries');
      expect(result, expectedPath);
    });

    test('getLibraryPath - standard call - returns expected absolute path with relative path', () async {
      // Act
      final result = await service.getLibraryPath('org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar');

      // Assert
      final expectedPath = p.join(tempDir.path, 'libraries', 'org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar');
      expect(result, expectedPath);
    });

    test('getAssetDirectory - standard call - returns expected absolute path', () async {
      // Act
      final result = await service.getAssetDirectory();

      // Assert
      final expectedPath = p.join(tempDir.path, 'assets');
      expect(result, expectedPath);
    });

    test('getGameDirectory - standard call - returns expected absolute path with instance id', () async {
      // Act
      final result = await service.getGameDirectory('test-instance');

      // Assert
      final expectedPath = p.join(tempDir.path, 'instances', 'test-instance');
      expect(result, expectedPath);
    });

    test('getNativesDirectory - standard call - returns expected absolute path with instance id', () async {
      // Act
      final result = await service.getNativesDirectory('test-instance');

      // Assert
      final expectedPath = p.join(tempDir.path, 'instances', 'test-instance', 'natives');
      expect(result, expectedPath);
    });

    test('getClientJarPath - standard call - returns expected absolute path with instance id', () async {
      // Act
      final result = await service.getClientJarPath('1.20.4');

      // Assert
      final expectedPath = p.join(tempDir.path, 'versions', '1.20.4', '1.20.4.jar');
      expect(result, expectedPath);
    });

    test('getJavaExecutablePath - standard call - returns fallback string', () async {
      // Act
      final result = await service.getJavaExecutablePath('17');

      // Assert
      expect(result, 'java');
    });

    test('createDirectory - folder does not exist - creates folder recursively', () async {
      // Arrange
      final relativePath = p.join('test', 'deep', 'folder');
      final fullPath = p.join(tempDir.path, relativePath);
      final dir = Directory(fullPath);

      expect(await dir.exists(), isFalse);

      // Act
      await service.createDirectory(relativePath);

      // Assert
      expect(await dir.exists(), isTrue);
    });

    test('createDirectory - folder already exists - does nothing', () async {
      // Arrange
      final relativePath = p.join('test', 'existing');
      final fullPath = p.join(tempDir.path, relativePath);
      final dir = Directory(fullPath);
      await dir.create(recursive: true);

      expect(await dir.exists(), isTrue);

      // Act
      await service.createDirectory(relativePath);

      // Assert
      expect(await dir.exists(), isTrue); // Ensure it didn't throw and still exists
    });
  });

  group('FileService extractNatives', () {
    test('extractNatives - valid jar with natives - extracts only dll, so, dylib, jnilib files', () async {
      // Arrange
      final jarPath = p.join(tempDir.path, 'natives.jar');
      final outputDir = p.join(tempDir.path, 'extracted');
      
      // Create a dummy zip/jar file
      final archive = Archive()
        ..addFile(ArchiveFile('lwjgl.dll', 10, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]))
        ..addFile(ArchiveFile('lwjgl.so', 5, [10, 11, 12, 13, 14]))
        ..addFile(ArchiveFile('lwjgl.dylib', 3, [15, 16, 17]))
        ..addFile(ArchiveFile('lwjgl.jnilib', 2, [18, 19]))
        ..addFile(ArchiveFile('META-INF/MANIFEST.MF', 12, 'Manifest data'.codeUnits))
        ..addFile(ArchiveFile('readme.txt', 15, 'Some text data.'.codeUnits));

      final encoder = ZipEncoder();
      final jarBytes = encoder.encode(archive);
      await File(jarPath).writeAsBytes(jarBytes);

      // Act
      await service.extractNatives(jarPath, outputDir);

      // Assert
      // Only the native files should exist in the output directory
      expect(await File(p.join(outputDir, 'lwjgl.dll')).exists(), isTrue);
      expect(await File(p.join(outputDir, 'lwjgl.so')).exists(), isTrue);
      expect(await File(p.join(outputDir, 'lwjgl.dylib')).exists(), isTrue);
      expect(await File(p.join(outputDir, 'lwjgl.jnilib')).exists(), isTrue);
      
      expect(await File(p.join(outputDir, 'MANIFEST.MF')).exists(), isFalse);
      expect(await File(p.join(outputDir, 'readme.txt')).exists(), isFalse);
      
      // Verify content of extracted file
      final extractedDll = await File(p.join(outputDir, 'lwjgl.dll')).readAsBytes();
      expect(extractedDll, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('extractNatives - jar does not exist - throws exception', () async {
      // Arrange
      final jarPath = p.join(tempDir.path, 'non_existent.jar');
      final outputDir = p.join(tempDir.path, 'extracted');
      
      // Act & Assert
      expect(
        () async => await service.extractNatives(jarPath, outputDir),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Native JAR not found'))),
      );
    });
  });
}
