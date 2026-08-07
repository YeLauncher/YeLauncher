import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/fabric_repository_remote.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';

import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';
import 'package:yelauncher/ui/core/toast/toast_service.dart';

import 'package:yelauncher/routing/breadcrumb_service.dart';

// Fakes


import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_styling_repository.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/download/cancellation_token.dart';

class FakeDownloadService implements DownloadService {

  @override
  Future<Result<void>> download(
    DownloadModel model, {
    void Function(int, int?)? onProgress,
    CancellationToken? cancellationToken,
  }) async => Result.success(null);
  @override
  Future<Result<void>> downloadAll(
    List<DownloadModel> models, {
    void Function(int, int?)? onProgress,
    CancellationToken? cancellationToken,
  }) async => Result.success(null);
  @override
  Future<Result<void>> downloadIfMissing(
    DownloadModel model, {
    void Function(int, int?)? onProgress,
    CancellationToken? cancellationToken,
  }) async => Result.success(null);
  @override
  Future<Result<bool>> isDownloaded(DownloadModel model) async =>
      Result.success(true);
}

class FakeJavaRepository implements JavaRepository {
  @override
  Future<Result<bool>> isInstalled(int version) async => Result.success(true);
  @override
  Future<Result<void>> install(
    int version, {
    void Function(double)? onProgress,
  }) async => Result.success(null);
  @override
  Future<Result<String>> getJavaExecutablePath(int version) async =>
      Result.success('java');
}

class FakeInstanceStylingRepository implements InstanceStylingRepository {

  @override
  List<String> get availableColors => ['0xFF4CAF50'];
  @override
  List<String> get availableIcons => ['assets/grass_block.png'];

  @override
  Color getColor(String? colorHex, {required Color fallback}) => fallback;
  @override
  IconData getIconData(String? iconName) => Icons.grass;
}

class FakeInstanceRepository implements InstanceRepository {
  InstanceModel? createdInstance;
  final List<InstanceModel> _instances = [
    InstanceModel(
      id: 'existing1',
      name: 'Duplicate Instance',
      minecraftVersion: '1.20.1',
      modLoader: 'vanilla',
      modLoaderVersion: '',
      isInstalled: true,
      icon: 'assets/grass_block.png',
      color: '0xFF4CAF50',
    ),
  ];

  @override
  Future<List<InstanceModel>> getInstances() async => _instances;
  @override
  Future<void> saveInstance(InstanceModel instance) async {}
  @override
  Future<void> deleteInstance(String id) async {}
  @override
  Future<void> openFolder(InstanceModel instance) async {}
  @override
  Future<void> openLogsFolder(InstanceModel instance) async {}
  @override
  Future<void> createInstance(InstanceModel instance) async {
    createdInstance = instance;
  }
}

class FakeMinecraftRepository implements MinecraftRepository {
  bool shouldFail = false;
  Duration delay = Duration.zero;

  @override
  Future<Result<List<MinecraftVersionModel>>> getVersions() async {
    if (delay != Duration.zero) await Future.delayed(delay);
    if (shouldFail) return Result.failure(Exception('Network Error'));

    return Result.success([
      MinecraftVersionModel(
        id: '1.20.1',
        type: 'release',
        releaseTime: DateTime.now(),
      ),
      MinecraftVersionModel(
        id: '1.19.4',
        type: 'release',
        releaseTime: DateTime.now(),
      ),
      MinecraftVersionModel(
        id: '1.20.2-pre1',
        type: 'snapshot',
        releaseTime: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<Result<List<MinecraftProfileModel>>> getProfiles() async =>
      throw UnimplementedError();
  @override
  Future<Result<MinecraftProfileModel?>> getSelectedProfile() async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> selectProfile(String uuid) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> removeProfile(String uuid) async =>
      throw UnimplementedError();
  @override
  Future<Result<MinecraftProfileModel>> authenticate() async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> addOfflineProfile(String nickname) async =>
      throw UnimplementedError();
  @override
  void cancelAuthentication() {}
  @override
  Future<Result<void>> install(
    InstanceModel instance, {
    void Function(int, int?)? onProgress,
    void Function(String)? onStepChanged,
  }) async => throw UnimplementedError();
  @override
  Future<Result<bool>> isInstalled(InstanceModel instance) async =>
      throw UnimplementedError();
  @override
  Future<Result<String>> getJavaVersion(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<MinecraftProcessModel>> run(InstanceModel instance) async =>
      throw UnimplementedError();
  @override
  Future<bool> isAuthenticated() async => false;
  @override
  Future<Result<void>> logout() async => throw UnimplementedError();
}

class FakeFabricRepository implements FabricRepositoryRemote {
  @override
  String get id => 'fabric';
  @override
  String get name => 'Fabric';
  @override
  String get icon => 'assets/fabric.svg';
  @override
  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  ) async {
    return Result.success([
      ModLoaderVersionModel(
        id: 'fabric-0.14.21',
        version: '0.14.21',
        type: 'stable',
      ),
      ModLoaderVersionModel(
        id: 'fabric-0.14.20',
        version: '0.14.20',
        type: 'stable',
      ),
    ]);
  }

  @override
  Future<Result<List<String>>> getLibrariesPath(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> install(
    String id, {
    String? minecraftVersion,
    void Function(int, int?)? onProgress,
  }) async => throw UnimplementedError();
  @override
  Future<Result<bool>> isInstalled(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> processInstallation(
    String id,
    String minecraftVersion, {
    String? javaExecutablePath,
  }) async => throw UnimplementedError();
}

class FakeForgeRepository implements ForgeRepository {
  @override
  String get id => 'forge';
  @override
  String get name => 'Forge';
  @override
  String get icon => 'assets/forge.svg';
  @override
  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  ) async {
    return Result.success([
      ModLoaderVersionModel(
        id: 'forge-47.2.0',
        version: '47.2.0',
        type: 'stable',
      ),
      ModLoaderVersionModel(
        id: 'forge-47.1.0',
        version: '47.1.0',
        type: 'stable',
      ),
      ModLoaderVersionModel(
        id: 'forge-47.0.0',
        version: '47.0.0',
        type: 'stable',
      ),
    ]);
  }

  @override
  Future<Result<String?>> getLatestVersion(String minecraftVersion) async =>
      const Result.success('47.2.0');
  @override
  Future<Result<String?>> getRecommendedVersion(
    String minecraftVersion,
  ) async => const Result.success('47.1.0');
  @override
  Future<Result<List<String>>> getLibrariesPath(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> install(
    String id, {
    String? minecraftVersion,
    void Function(int, int?)? onProgress,
  }) async => throw UnimplementedError();
  @override
  Future<Result<bool>> isInstalled(String id) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> processInstallation(
    String id,
    String minecraftVersion, {
    String? javaExecutablePath,
  }) async => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({
    required FakeInstanceRepository mockInstanceRepo,
    required FakeMinecraftRepository mockMinecraftRepo,
    required FakeFabricRepository mockFabricRepo,
    required FakeForgeRepository mockForgeRepo,
  }) {
    return MultiProvider(
      providers: [
        Provider<InstanceRepository>.value(value: mockInstanceRepo),
        Provider<MinecraftRepository>.value(value: mockMinecraftRepo),
        Provider<FabricRepositoryRemote>.value(value: mockFabricRepo),
        Provider<ForgeRepository>.value(value: mockForgeRepo),
        Provider<List<ModLoaderRepository>>.value(
          value: [mockFabricRepo, mockForgeRepo],
        ),
        Provider<DownloadService>.value(value: FakeDownloadService()),
        Provider<JavaRepository>.value(value: FakeJavaRepository()),
        Provider<InstanceStylingRepository>.value(
          value: FakeInstanceStylingRepository(),
        ),
        Provider<ToastService>.value(value: ToastService()),
        ChangeNotifierProvider<BreadcrumbService>(
          create: (_) => BreadcrumbService(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (context) =>
                InstanceScreenViewModel(instanceRepository: context.read()),
            child: Consumer<InstanceScreenViewModel>(
              builder: (context, viewModel, _) =>
                  InstancesScreen(viewModel: viewModel),
            ),
          ),
        ),
      ),
    );
  }

  group('Instance Creation Dialog Extended Tests', () {
    late FakeInstanceRepository mockInstanceRepo;
    late FakeMinecraftRepository mockMinecraftRepo;
    late FakeFabricRepository mockFabricRepo;
    late FakeForgeRepository mockForgeRepo;

    setUp(() {
      mockInstanceRepo = FakeInstanceRepository();
      mockMinecraftRepo = FakeMinecraftRepository();
      mockFabricRepo = FakeFabricRepository();
      mockForgeRepo = FakeForgeRepository();
    });

    Future<void> openDialog(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildTestApp(
          mockInstanceRepo: mockInstanceRepo,
          mockMinecraftRepo: mockMinecraftRepo,
          mockFabricRepo: mockFabricRepo,
          mockForgeRepo: mockForgeRepo,
        ),
      );
      // Bypass the SplashScreen's CircularProgressIndicator and 1.5s delay
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final createBtn = find.byKey(const ValueKey('create_instance_button'));
      await tester.tap(createBtn);
      await tester.pumpAndSettle();
    }

    testWidgets('Test 1: Happy Path', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openDialog(tester);

      await tester.enterText(
        find.byKey(const ValueKey('instance_name_input')),
        'Test Instance',
      );
      await tester.pumpAndSettle();

      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('version_item_1.20.1')));
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mod_loader_button_fabric')));
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(mockInstanceRepo.createdInstance, isNotNull);
      expect(mockInstanceRepo.createdInstance!.name, 'Test Instance');
      expect(mockInstanceRepo.createdInstance!.minecraftVersion, '1.20.1');
      expect(mockInstanceRepo.createdInstance!.modLoader, 'fabric');
    });

    testWidgets('Test 2a: Empty Name Validation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openDialog(tester);
      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('instance_name_input')), findsOneWidget);
    });

    testWidgets('Test 2b: Duplicate Name Validation', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openDialog(tester);
      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('instance_name_input')),
        'Duplicate Instance',
      );
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('instance_name_input')), findsOneWidget);
    });

    testWidgets('Test 2c: No Version Validation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openDialog(tester);
      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('instance_name_input')),
        'Valid Name',
      );
      await tester.pumpAndSettle();

      // Tap next to go to Appearance
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Verify we are on Appearance (no name input)
      expect(find.byKey(const ValueKey('instance_name_input')), findsNothing);

      // Tap next to go to Version
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Verify we are on Version step
      expect(
        find.byKey(const ValueKey('version_search_input')),
        findsOneWidget,
      );

      // Try to proceed without selecting version
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Should still be on Version step
      expect(
        find.byKey(const ValueKey('version_search_input')),
        findsOneWidget,
      );
    });

    testWidgets('Test 3: Search and Filtering Logic', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openDialog(tester);
      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('instance_name_input')),
        'Filter Test',
      );
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Search '1.19'
      await tester.enterText(
        find.byKey(const ValueKey('version_search_input')),
        '1.19',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version_item_1.19.4')), findsOneWidget);
      expect(find.byKey(const ValueKey('version_item_1.20.1')), findsNothing);

      // Search non-existent
      await tester.enterText(
        find.byKey(const ValueKey('version_search_input')),
        '1.99',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version_item_1.19.4')), findsNothing);

      // Clear search
      await tester.enterText(
        find.byKey(const ValueKey('version_search_input')),
        '',
      );
      await tester.pumpAndSettle();

      // Snapshots toggle
      expect(
        find.byKey(const ValueKey('version_item_1.20.2-pre1')),
        findsNothing,
      );
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'CoreCheckbox',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('version_item_1.20.2-pre1')),
        findsOneWidget,
      );
    });

    testWidgets('Test 5: Mod Loader Edge Cases (Forge)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openDialog(tester);
      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('instance_name_input')),
        'Forge Test',
      );
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('version_item_1.20.1')));
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Select Forge
      await tester.tap(find.byKey(const ValueKey('mod_loader_button_forge')));
      await tester.pumpAndSettle();

      expect(find.text('Latest'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Click Latest
      await tester.tap(find.text('Latest'));
      await tester.pumpAndSettle();

      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(mockInstanceRepo.createdInstance!.modLoader, 'forge');
      expect(mockInstanceRepo.createdInstance!.modLoaderVersion, '47.2.0');
    });

    testWidgets('Test 6: Error States & Networking', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      mockMinecraftRepo.shouldFail = true;
      await openDialog(tester);

      final nextBtn = find.byKey(
        const ValueKey('instance_creation_next_button'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('instance_name_input')),
        'Error Test',
      );
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('version_item_1.20.1')), findsNothing);
    });
  });
}
