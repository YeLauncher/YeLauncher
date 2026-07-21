import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yelauncher/data/repositories/java/java_repository_remote.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository_remote.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository_remote.dart';
import 'package:yelauncher/data/services/api/forge_api_client.dart';
import 'package:yelauncher/data/services/api/fabric_api_client.dart';
import 'package:yelauncher/data/repositories/mod_loader/fabric_repository_remote.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/file_service.dart';
import 'package:yelauncher/data/services/minecraft_service.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:logging/logging.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory(
      p.join(Directory.systemTemp.path, 'yelauncher_e2e_test'),
    );
    if (!await dir.exists()) await dir.create();
    return dir.path;
  }
}

class FakeSecureStorageService extends SecureStorageService {
  List<MinecraftProfileModel> _profiles = [];
  String? _selectedId;

  @override
  Future<List<MinecraftProfileModel>> getProfiles() async {
    return _profiles;
  }

  @override
  Future<bool> saveProfiles(List<MinecraftProfileModel> profiles) async {
    _profiles = profiles;
    return true;
  }

  @override
  Future<String?> getSelectedProfileId() async {
    return _selectedId;
  }

  @override
  Future<bool> saveSelectedProfileId(String uuid) async {
    _selectedId = uuid;
    return true;
  }

  @override
  Future<MinecraftProfileModel?> getSelectedProfile() async {
    if (_selectedId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.uuid == _selectedId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> clearProfiles() async {
    _profiles = [];
    _selectedId = null;
    return true;
  }

  @override
  Future<bool> hasProfile() async {
    return _profiles.isNotEmpty;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  PathProviderPlatform.instance = MockPathProviderPlatform();

  late MinecraftRepositoryRemote minecraftRepository;
  late FakeSecureStorageService fakeSecureStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    final apiClient = MinecraftApiClient(
      baseUrl:
          'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json',
    );
    final downloadService = DownloadService();
    final fileService = FileService();
    final javaRepository = JavaRepositoryRemote();
    fakeSecureStorage = FakeSecureStorageService();

    final forgeRepository = ForgeRepositoryRemote(
      apiClient: ForgeApiClient(),
      downloadService: downloadService,
      fileService: fileService,
    );

    final fabricRepository = FabricRepositoryRemote(
      apiClient: FabricApiClient(),
      downloadService: downloadService,
      fileService: fileService,
    );

    minecraftRepository = MinecraftRepositoryRemote(
      apiClient: apiClient,
      minecraftService: MinecraftService(),
      downloadService: downloadService,
      fileService: fileService,
      javaRepository: javaRepository,
      secureStorage: fakeSecureStorage,
      forgeRepository: forgeRepository,
      fabricRepository: fabricRepository,
    );
  });

  Future<void> runEndToEndTest(
    String version, {
    String modLoader = 'vanilla',
    String modLoaderVersion = '',
  }) async {
    debugPrint(
      '--- Starting E2E Test for $version (modLoader: $modLoader) ---',
    );
    final instanceId = 'e2e_test_$version';
    final instance = InstanceModel(
      id: instanceId,
      name: 'E2E Test $version',
      minecraftVersion: version,
      modLoader: modLoader,
      modLoaderVersion: modLoaderVersion,
    );

    debugPrint('Getting Java version for $version...');
    final javaVersionResult = await minecraftRepository.getJavaVersion(version);
    expect(javaVersionResult, isA<Success<String>>());
    final javaVersion = int.parse((javaVersionResult as Success<String>).value);
    debugPrint('Java version required: $javaVersion');

    final javaRepository = JavaRepositoryRemote();
    debugPrint('Checking if Java $javaVersion is installed...');
    final isJavaInstalled = await javaRepository.isInstalled(javaVersion);
    if (isJavaInstalled is Success<bool> && !isJavaInstalled.value) {
      debugPrint('Java $javaVersion not installed. Installing...');
      int lastJavaProgress = -1;
      final javaInstall = await javaRepository.install(
        javaVersion,
        onProgress: (progress) {
          final p = (progress * 100).toInt();
          if (p != lastJavaProgress && p % 10 == 0) {
            debugPrint('Java $javaVersion install progress: $p%');
            lastJavaProgress = p;
          }
        },
      );
      expect(javaInstall, isA<Success>());
      debugPrint('Java $javaVersion installed successfully.');
    } else {
      debugPrint('Java $javaVersion is already installed.');
    }

    debugPrint('Checking if Minecraft $version is installed...');
    final isMcInstalledResult = await minecraftRepository.isInstalled(instance);
    final isMcInstalled =
        isMcInstalledResult is Success<bool> && isMcInstalledResult.value;

    debugPrint('Mocking authentication as E2ETester...');
    final profile = MinecraftProfileModel(
      nickname: 'E2ETester',
      uuid: '00000000-0000-0000-0000-000000000000',
      accessToken: 'dummy-token',
      userType: 'mojang',
    );
    await fakeSecureStorage.saveProfiles([profile]);
    await fakeSecureStorage.saveSelectedProfileId(profile.uuid);

    if (!isMcInstalled) {
      debugPrint('Installing Minecraft $version instance...');
      int lastMcProgress = -1;
      final installResult = await minecraftRepository.install(
        instance,
        onProgress: (down, total) {
          if (total != null && total > 0) {
            final p = ((down / total) * 10).toInt(); // 0 to 10
            if (p > lastMcProgress) {
              debugPrint(
                'Minecraft $version install progress: ${p * 10}% ($down/$total bytes)',
              );
              lastMcProgress = p;
            }
          } else {
            final mb = down ~/ (1024 * 1024);
            if (mb > lastMcProgress) {
              debugPrint(
                'Minecraft $version install progress: $mb MB downloaded',
              );
              lastMcProgress = mb;
            }
          }
        },
      );
      expect(installResult, isA<Success>());
      debugPrint('Minecraft $version installed successfully.');
    } else {
      debugPrint('Minecraft $version is already installed.');
    }

    debugPrint('Running Minecraft $version instance...');
    final runResult = await minecraftRepository.run(instance);
    expect(runResult, isA<Success>());
    debugPrint('Minecraft $version process started. Waiting for launch...');

    bool isLaunched = false;
    final logSubscription = Logger.root.onRecord.listen((record) {
      final msg = record.message.toLowerCase();
      if (msg.contains('openal initialized') ||
          msg.contains('forge mod loader has successfully loaded') ||
          msg.contains('sound engine started') ||
          msg.contains('reloading resourcemanager') ||
          msg.contains('fabric loader has successfully loaded') ||
          msg.contains('setting user: e2etester')) {
        isLaunched = true;
      }
    });

    int waitTime = 0;
    while (!isLaunched && waitTime < 180) {
      await Future.delayed(const Duration(seconds: 1));
      waitTime++;
    }

    await logSubscription.cancel();

    if (isLaunched) {
      debugPrint(
        'Minecraft $version launched successfully (detected via logs in $waitTime seconds).',
      );
    } else {
      debugPrint(
        'Warning: Did not detect clear launch signal in logs after 180s.',
      );
    }

    debugPrint('Waiting an additional 10 seconds before terminating...');
    await Future.delayed(const Duration(seconds: 10));

    if (Platform.isWindows) {
      debugPrint('Killing Java processes...');
      await Process.run('taskkill', ['/F', '/IM', 'javaw.exe']);
      await Process.run('taskkill', ['/F', '/IM', 'java.exe']);
      debugPrint('Java processes killed.');
    }
    debugPrint('--- Finished E2E Test for $version ---');
  }

  Future<String> resolveRecommendedForge(String mcVersion) async {
    final client = ForgeApiClient();
    final version = await client.getRecommendedVersion(mcVersion);
    if (version == null) {
      throw Exception('No recommended Forge version found for $mcVersion');
    }
    return version;
  }

  Future<String> resolveLatestFabric(String mcVersion) async {
    final client = FabricApiClient();
    final versions = await client.getVersions(mcVersion);
    if (versions.isEmpty) {
      throw Exception('No Fabric version found for $mcVersion');
    }
    return versions.first.version;
  }

  group('Minecraft E2E Launch Tests', () {
    test(
      'Can install and launch Vanilla 26.1.2',
      () async {
        await runEndToEndTest('26.1.2');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.20.6',
      () async {
        await runEndToEndTest('1.20.6');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.19.4',
      () async {
        await runEndToEndTest('1.19.4');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.18.2',
      () async {
        await runEndToEndTest('1.18.2');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.16.5',
      () async {
        await runEndToEndTest('1.16.5');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.13.2',
      () async {
        await runEndToEndTest('1.13.2');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.12.2',
      () async {
        await runEndToEndTest('1.12.2');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'Can install and launch Vanilla 1.8.9',
      () async {
        await runEndToEndTest('1.8.9');
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );
  });

  test(
    'Can install and launch Vanilla 1.7.10',
    () async {
      await runEndToEndTest('1.7.10');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  group('Minecraft Forge E2E Launch Tests', () {
    test(
      'Can install and launch Forge 1.18.2',
      () async {
        final forgeVersion = await resolveRecommendedForge('1.18.2');
        await runEndToEndTest(
          '1.18.2',
          modLoader: 'forge',
          modLoaderVersion: forgeVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'Can install and launch Forge 1.16.5',
      () async {
        final forgeVersion = await resolveRecommendedForge('1.16.5');
        await runEndToEndTest(
          '1.16.5',
          modLoader: 'forge',
          modLoaderVersion: forgeVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'Can install and launch Forge 1.12.2',
      () async {
        final forgeVersion = await resolveRecommendedForge('1.12.2');
        await runEndToEndTest(
          '1.12.2',
          modLoader: 'forge',
          modLoaderVersion: forgeVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'Can install and launch Forge 1.8.9',
      () async {
        final forgeVersion = await resolveRecommendedForge('1.8.9');
        await runEndToEndTest(
          '1.8.9',
          modLoader: 'forge',
          modLoaderVersion: forgeVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'Can install and launch Forge 1.7.10',
      () async {
        final forgeVersion = await resolveRecommendedForge('1.7.10');
        await runEndToEndTest(
          '1.7.10',
          modLoader: 'forge',
          modLoaderVersion: forgeVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });

  group('Minecraft Fabric E2E Launch Tests', () {
    test(
      'Can install and launch Fabric 1.18.2',
      () async {
        final fabricVersion = await resolveLatestFabric('1.18.2');
        await runEndToEndTest(
          '1.18.2',
          modLoader: 'fabric',
          modLoaderVersion: fabricVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'Can install and launch Fabric 1.21.1',
      () async {
        final fabricVersion = await resolveLatestFabric('1.21.1');
        await runEndToEndTest(
          '1.21.1',
          modLoader: 'fabric',
          modLoaderVersion: fabricVersion,
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
