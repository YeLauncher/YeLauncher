import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:yelauncher/config/dependencies.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/main.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../test/integration_mocks.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Flow', () {
    provideDummy<Result<List<ModLoaderVersionModel>>>(Result.success([]));
    provideDummy<Result<List<MinecraftVersionModel>>>(Result.success([]));
    provideDummy<Result<List<ContentItem>>>(Result.success([]));
    provideDummy<Result<ContentItem>>(Result.success(ContentItem(
      id: '', slug: '', projectType: '', title: '', description: '',
      downloads: 0,
      iconUrl: '', author: '', gallery: [],
    )));
    provideDummy<Result<List<ContentVersion>>>(Result.success([]));
    provideDummy<Result<MinecraftProcessModel>>(Result.success(
      MinecraftProcessModel(
        exitCode: Future.value(0),
        stdout: const Stream.empty(),
        stderr: const Stream.empty(),
        kill: () => true,
      )
    ));
    provideDummy<Result<List<MinecraftProfileModel>>>(Result.success([]));
    provideDummy<Result<MinecraftProfileModel?>>(Result.success(null));
    provideDummy<Result<void>>(Result.success(null));
    
    late MockMinecraftRepository mockMinecraftRepo;
    late MockContentRepository mockContentRepo;
    late MockModLoaderRepository mockModLoaderRepo;
    late MockDownloadService mockDownloadService;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() async {
      mockMinecraftRepo = MockMinecraftRepository();
      mockContentRepo = MockContentRepository();
      mockModLoaderRepo = MockModLoaderRepository();
      mockDownloadService = MockDownloadService();
      mockSettingsRepo = MockSettingsRepository();

      when(mockSettingsRepo.currentLocale).thenReturn(const Locale('en'));

      // Ensure storage is initialized
      final secureStorage = SecureStorageService();
      final profile = MinecraftProfileModel(
        nickname: 'TestAccount',
        uuid: '00000000-0000-0000-0000-000000000000',
        accessToken: 'dummy-token',
        userType: 'mojang',
      );
      await secureStorage.saveProfiles([profile]);
      await secureStorage.saveSelectedProfileId(profile.uuid);

      // Setup basic mocks
      when(mockMinecraftRepo.getVersions()).thenAnswer((_) async => Result.success([
        MinecraftVersionModel(id: '1.20.1', type: 'release', releaseTime: DateTime.now()),
      ]));
      when(mockMinecraftRepo.run(any)).thenAnswer((_) async => Result.success(
        MinecraftProcessModel(
          exitCode: Future.value(0),
          stdout: const Stream.empty(),
          stderr: const Stream.empty(),
          kill: () => true,
        )
      ));
      
      final fabricItem = ContentItem(
          id: 'fabric-api',
          slug: 'fabric-api',
          projectType: 'mod',
          title: 'Fabric API',
          description: 'Core API for Fabric.',
          downloads: 1000,
          iconUrl: null,
          author: 'modmuss50',
          gallery: [],
        );
      when(mockContentRepo.searchContent(
        query: anyNamed('query'),
        projectType: anyNamed('projectType'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success([fabricItem]));
      when(mockContentRepo.getContent(any)).thenAnswer((_) async => Result.success(fabricItem));
      when(mockContentRepo.getVersions(any)).thenAnswer((_) async => Result.success([
        ContentVersion(
          id: 'fabric-api-version',
          projectId: 'fabric-api',
          name: 'Fabric API 0.14.21',
          versionNumber: '0.14.21',
          versionType: 'release',
          gameVersions: ['1.20.1'],
          loaders: ['fabric'],
          files: [],
        ),
      ]));

      when(mockModLoaderRepo.id).thenReturn('fabric');
      when(mockModLoaderRepo.name).thenReturn('Fabric');
      when(mockModLoaderRepo.icon).thenReturn('assets/fabric.svg');

      when(mockModLoaderRepo.getVersions(any)).thenAnswer((_) async => Result.success([
        ModLoaderVersionModel(id: '0.14.21', version: '0.14.21', type: 'stable'),
      ]));

      when(mockDownloadService.download(any, onProgress: anyNamed('onProgress')))
          .thenAnswer((_) async => Result.success(null));
      when(mockDownloadService.downloadIfMissing(any, onProgress: anyNamed('onProgress')))
          .thenAnswer((_) async => Result.success(null));
    });

    testWidgets('Create, install, and launch instance', (tester) async {
      // 1. Build the app with mocked dependencies injected over local providers
      final List<SingleChildWidget> integrationProviders = List.from(providersLocal);
      
      // We replace specific providers by adding them at the end (Provider uses the nearest ancestor)
      integrationProviders.addAll([
        Provider<MinecraftRepository>.value(value: mockMinecraftRepo),
        Provider<ContentRepository>.value(value: mockContentRepo),
        Provider<List<ModLoaderRepository>>.value(value: [mockModLoaderRepo]),
        Provider<DownloadService>.value(value: mockDownloadService),
        ChangeNotifierProvider<SettingsRepository>.value(value: mockSettingsRepo),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: integrationProviders,
          child: const YeLauncherApp(),
        ),
      );

      // Wait for app to start and load instances
      await tester.pumpAndSettle();

      // 2. Create Instance Flow
      // Tap 'Create Instance'
      await tester.tap(find.byKey(const ValueKey('create_instance_button')));
      await tester.pumpAndSettle();

      // Enter instance name
      await tester.enterText(find.byKey(const ValueKey('instance_name_input')), 'E2E Instance');
      
      // Tap Next to go to Version step
      await tester.tap(find.byKey(const ValueKey('instance_creation_next_button')));
      await tester.pumpAndSettle();

      // Select '1.20.1' version
      await tester.tap(find.byKey(const ValueKey('version_item_1.20.1')));
      await tester.pumpAndSettle();

      // Tap Next to go to Mod Loader step
      await tester.tap(find.byKey(const ValueKey('instance_creation_next_button')));
      await tester.pumpAndSettle();

      // Select 'fabric' mod loader
      await tester.tap(find.byKey(const ValueKey('mod_loader_button_fabric')));
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.byKey(const ValueKey('instance_creation_next_button')));
      await tester.pumpAndSettle();

      // Verify the instance was created (wait for the card to appear)
      expect(find.text('E2E Instance'), findsWidgets);

      // Get the instance ID generated by the creation process by reading the provider state
      // Actually, we can just tap the Install button for the new instance by finding the button that contains 'Install'
      // But first we should navigate to Content to install something! Wait, the instruction said:
      // "Switch to the Content tab. Search for a specific mod..."
      
      // 3. Content Installation Flow
      await tester.tap(find.byKey(const ValueKey('nav_content')));
      await tester.pumpAndSettle();

      // Search for Fabric API
      await tester.enterText(find.byKey(const ValueKey('content_search_input')), 'Fabric API');
      await tester.pump(const Duration(seconds: 2)); // allow debounce and search to complete
      await tester.pumpAndSettle();

      // Tap the info button on the mod card
      await tester.tap(find.byIcon(Symbols.info).first);
      await tester.pumpAndSettle();

      // Tap the Versions tab in the detail dialog
      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      // Tap "Install" on the Detail Dialog (it's a download icon)
      await tester.tap(find.byIcon(Symbols.download_rounded).first);
      await tester.pumpAndSettle();

      // Wait for async file I/O in _loadFreshInstances
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      try {
        await tester.tap(find.text('E2E Instance'));
        await tester.pumpAndSettle();
      } catch (e) {
        final tree = tester.allWidgets.map((w) => w.toString()).join('\n');
        File('tree.txt').writeAsStringSync(tree);
        rethrow;
      }

      // Tap the bottom Install button
      await tester.tap(find.text('Install').last);
      // Wait for installation
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 4. Launch Instance Flow
      // Close detail dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Switch back to Instances Tab
      await tester.tap(find.byKey(const ValueKey('nav_instances')));
      await tester.pumpAndSettle();

      // Tap 'Play' on the instance card
      // Since it's the only instance, we can just tap Play.
      await tester.tap(find.text('Play').first);
      
      // pump to start launch
      await tester.pump();
      
      // Verify mock was called
      verify(mockMinecraftRepo.run(any)).called(1);
    });
  });
}
