import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/api/models/argument_api_model.dart';
import 'package:yelauncher/data/services/api/models/asset_index_api_model.dart';
import 'package:yelauncher/data/services/api/models/client_api_model.dart';
import 'package:yelauncher/data/services/api/models/library_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_api_model.dart';
import 'package:yelauncher/data/services/api/models/version_requirements_api_model.dart';
import 'package:yelauncher/data/services/instance_service.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/result.dart';

import 'instance_service_test.mocks.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;

  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

@GenerateNiceMocks([
  MockSpec<MinecraftApiClient>(),
  MockSpec<JavaRepository>(),
])
void main() {
  late InstanceService service;
  late MockMinecraftApiClient mockApiClient;
  late MockJavaRepository mockJavaRepository;
  late Directory tempDir;

  final testInstance = InstanceModel(
    id: 'test-instance-123',
    name: 'Test Instance',
    minecraftVersion: '1.20.4',
    modLoader: 'fabric',
    modLoaderVersion: '0.15.6',
    lastPlayed: DateTime.now(),
    javaMemory: 2048,
    windowWidth: 854,
    windowHeight: 480,
  );

  final testVersionApiModel = VersionApiModel(
    id: '1.20.4',
    type: 'release',
    url: 'https://example.com/1.20.4.json',
    time: DateTime.now(),
    releaseTime: DateTime.now(),
    complianceLevel: 1,
  );

  final testRequirementsApiModel = VersionRequirementsApiModel(
    id: '1.20.4',
    mainClass: 'net.minecraft.client.main.Main',
    javaVersion: '17',
    client: ClientApiModel(url: 'test.jar', sha1: 'test', size: 100),
    arguments: [
      ArgumentApiModel(
        rules: [],
        values: ['--username', '\${auth_player_name}'],
        type: 'game',
      ),
    ],
    libraries: [
      LibraryApiModel(
        name: 'com.mojang:test:1.0',
        path: 'com/mojang/test/1.0/test-1.0.jar',
        isNative: false,
        url: 'test.jar',
        sha1: 'test',
        size: 100,
        rules: [],
      )
    ],
    assetIndex: AssetIndexApiModel(
      id: '1.20',
      sha1: 'test',
      size: 100,
      url: 'test.json',
      totalSize: 100,
    ),
  );

  setUp(() async {
    provideDummy<Result<VersionApiModel>>(Success(testVersionApiModel));
    provideDummy<Result<VersionRequirementsApiModel>>(Success(testRequirementsApiModel));
    provideDummy<Result<bool>>(const Success(true));
    provideDummy<Result<String>>(const Success(''));
    provideDummy<Result<void>>(const Success(null));

    mockApiClient = MockMinecraftApiClient();
    mockJavaRepository = MockJavaRepository();
    service = InstanceService(
      apiClient: mockApiClient,
      javaRepository: mockJavaRepository,
    );

    tempDir = await Directory.systemTemp.createTemp('instance_service_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    // Ensure we stop the instance to kill the process if it's still running
    service.stop(testInstance);
    
    // Tiny delay to allow process to exit and close streams so we can delete the temp directory on Windows
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore file lock errors from pending stream closures
      }
    }
  });

  group('InstanceService', () {
    test('run - instance already running - returns early without calling API', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Success(testVersionApiModel));
      when(mockApiClient.getRequirements(any)).thenAnswer((_) async => Success(testRequirementsApiModel));
      when(mockJavaRepository.isInstalled(any)).thenAnswer((_) async => const Success(true));
      
      final dummyExecutable = Platform.isWindows ? 'cmd.exe' : 'sh';
      when(mockJavaRepository.getJavaExecutablePath(any)).thenAnswer((_) async => Success(dummyExecutable));

      // Act
      await service.run(testInstance); // First run launches it
      expect(service.isRunning(testInstance.id), isTrue);
      
      await service.run(testInstance); // Second run should return early

      // Assert
      // API should only be called once from the first launch
      verify(mockApiClient.getVersion(any)).called(1);
    });

    test('run - API fails to get version - stops execution', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Failure(Exception('API Error')));

      // Act
      await service.run(testInstance);

      // Assert
      verify(mockApiClient.getVersion(testInstance.minecraftVersion)).called(1);
      verifyNever(mockApiClient.getRequirements(any));
      expect(service.isRunning(testInstance.id), isFalse);
    });

    test('run - API fails to get requirements - stops execution', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Success(testVersionApiModel));
      when(mockApiClient.getRequirements(any)).thenAnswer((_) async => Failure(Exception('API Error')));

      // Act
      await service.run(testInstance);

      // Assert
      verify(mockApiClient.getVersion(testInstance.minecraftVersion)).called(1);
      verify(mockApiClient.getRequirements(testVersionApiModel)).called(1);
      verifyNever(mockJavaRepository.isInstalled(any));
      expect(service.isRunning(testInstance.id), isFalse);
    });

    test('run - Java is not installed and install fails - stops execution', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Success(testVersionApiModel));
      when(mockApiClient.getRequirements(any)).thenAnswer((_) async => Success(testRequirementsApiModel));
      when(mockJavaRepository.isInstalled(17)).thenAnswer((_) async => const Success(false));
      when(mockJavaRepository.install(17)).thenAnswer((_) async => Failure(Exception('Install failed')));

      // Act
      await service.run(testInstance);

      // Assert
      verify(mockJavaRepository.isInstalled(17)).called(1);
      verify(mockJavaRepository.install(17)).called(1);
      verifyNever(mockJavaRepository.getJavaExecutablePath(any));
      expect(service.isRunning(testInstance.id), isFalse);
    });

    test('run - Java executable path retrieval fails - stops execution', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Success(testVersionApiModel));
      when(mockApiClient.getRequirements(any)).thenAnswer((_) async => Success(testRequirementsApiModel));
      when(mockJavaRepository.isInstalled(17)).thenAnswer((_) async => const Success(true));
      when(mockJavaRepository.getJavaExecutablePath(17)).thenAnswer((_) async => Failure(Exception('Path failed')));

      // Act
      await service.run(testInstance);

      // Assert
      verify(mockJavaRepository.getJavaExecutablePath(17)).called(1);
      expect(service.isRunning(testInstance.id), isFalse);
    });

    test('run - all dependencies succeed - launches process and tracks it', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Success(testVersionApiModel));
      when(mockApiClient.getRequirements(any)).thenAnswer((_) async => Success(testRequirementsApiModel));
      when(mockJavaRepository.isInstalled(17)).thenAnswer((_) async => const Success(true));
      
      final dummyExecutable = Platform.isWindows ? 'cmd.exe' : 'sh';
      when(mockJavaRepository.getJavaExecutablePath(17)).thenAnswer((_) async => Success(dummyExecutable));

      // Act
      await service.run(testInstance);

      // Assert
      expect(service.isRunning(testInstance.id), isTrue);
    });

    test('stop - running instance - kills process and untracks it', () async {
      // Arrange
      when(mockApiClient.getVersion(any)).thenAnswer((_) async => Success(testVersionApiModel));
      when(mockApiClient.getRequirements(any)).thenAnswer((_) async => Success(testRequirementsApiModel));
      when(mockJavaRepository.isInstalled(17)).thenAnswer((_) async => const Success(true));
      
      final dummyExecutable = Platform.isWindows ? 'cmd.exe' : 'sh';
      when(mockJavaRepository.getJavaExecutablePath(17)).thenAnswer((_) async => Success(dummyExecutable));

      await service.run(testInstance);
      expect(service.isRunning(testInstance.id), isTrue);

      // Act
      service.stop(testInstance);

      // Assert
      expect(service.isRunning(testInstance.id), isFalse);
    });
    
    test('stop - non-running instance - ignores gracefully', () async {
      // Arrange
      expect(service.isRunning(testInstance.id), isFalse);

      // Act
      service.stop(testInstance); // Should not throw

      // Assert
      expect(service.isRunning(testInstance.id), isFalse);
    });
  });
}
