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
import 'package:flutter/gestures.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';
import 'package:yelauncher/ui/instances/widgets/instance_card.dart';
import 'package:yelauncher/ui/core/button.dart';

import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';
import 'package:yelauncher/ui/core/toast/toast_service.dart';
import 'package:yelauncher/routing/breadcrumb_service.dart';



import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_styling_repository.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/download/cancellation_token.dart';

class FakeDownloadService implements DownloadService {

  @override Future<Result<void>> download(DownloadModel model, {void Function(int, int?)? onProgress, CancellationToken? cancellationToken}) async => Result.success(null);
  @override Future<Result<void>> downloadAll(List<DownloadModel> models, {void Function(int, int?)? onProgress, CancellationToken? cancellationToken}) async => Result.success(null);
  @override Future<Result<void>> downloadIfMissing(DownloadModel model, {void Function(int, int?)? onProgress, CancellationToken? cancellationToken}) async => Result.success(null);
  @override Future<Result<bool>> isDownloaded(DownloadModel model) async => Result.success(true);
}

class FakeJavaRepository implements JavaRepository {
  @override Future<Result<bool>> isInstalled(int version) async => Result.success(true);
  @override Future<Result<void>> install(int version, {void Function(double)? onProgress}) async => Result.success(null);
  @override Future<Result<String>> getJavaExecutablePath(int version) async => Result.success('java');
}

class FakeInstanceStylingRepository implements InstanceStylingRepository {

  @override List<String> get availableColors => ['0xFF4CAF50'];
  @override List<String> get availableIcons => ['assets/grass_block.png'];

  @override Color getColor(String? colorHex, {required Color fallback}) => fallback;
  @override IconData getIconData(String? iconName) => Icons.grass;
}

class FakeInstanceRepository implements InstanceRepository {
  final List<InstanceModel> _instances = [
    InstanceModel(
      id: 'test_instance',
      name: 'Test Uninstalled Instance',
      icon: 'assets/grass_block.png',
      color: '0xFF4CAF50',
      minecraftVersion: '1.20.1',
      modLoader: 'vanilla',
      modLoaderVersion: '',
      isInstalled: false, // This is crucial for the install button to show
    ),
  ];

  @override Future<List<InstanceModel>> getInstances() async => _instances;
  @override Future<void> saveInstance(InstanceModel instance) async {}
  @override Future<void> deleteInstance(String id) async {}
  @override Future<void> openFolder(InstanceModel instance) async {}
  @override Future<void> openLogsFolder(InstanceModel instance) async {}
  @override Future<void> createInstance(InstanceModel instance) async {}
}

class FakeMinecraftRepository implements MinecraftRepository {
  bool installCalled = false;
  bool shouldFailInstall = false;
  InstanceModel? installedInstance;

  @override Future<Result<List<MinecraftProfileModel>>> getProfiles() async => throw UnimplementedError();
  @override Future<Result<MinecraftProfileModel?>> getSelectedProfile() async => throw UnimplementedError();
  @override Future<Result<void>> selectProfile(String uuid) async => throw UnimplementedError();
  @override Future<Result<void>> removeProfile(String uuid) async => throw UnimplementedError();
  @override Future<Result<MinecraftProfileModel>> authenticate() async => throw UnimplementedError();
  @override Future<Result<void>> addOfflineProfile(String nickname) async => throw UnimplementedError();
  @override void cancelAuthentication() {}
  @override Future<Result<List<MinecraftVersionModel>>> getVersions() async => throw UnimplementedError();
  
  @override
  Future<Result<void>> install(
    InstanceModel instance, {
    void Function(int, int?)? onProgress,
    void Function(String)? onStepChanged,
  }) async {
    installCalled = true;
    installedInstance = instance;
    
    // Simulate some installation progress
    if (onStepChanged != null) {
      onStepChanged('Downloading assets...');
    }
    if (onProgress != null) {
      onProgress(500, 1000);
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress(1000, 1000);
    }
    
    if (shouldFailInstall) {
      return Result.failure(Exception('Test install failure'));
    }
    
    return const Result.success(null);
  }

  @override Future<Result<bool>> isInstalled(InstanceModel instance) async => const Result.success(false);
  @override Future<Result<String>> getJavaVersion(String id) async => const Result.success('17');
  @override Future<Result<MinecraftProcessModel>> run(InstanceModel instance) async => throw UnimplementedError();
  @override Future<bool> isAuthenticated() async => false;
  @override Future<Result<void>> logout() async => throw UnimplementedError();
}

class FakeFabricRepository implements FabricRepositoryRemote {
  @override String get id => 'fabric';
  @override String get name => 'Fabric';
  @override String get icon => 'assets/fabric.svg';
  @override Future<Result<List<ModLoaderVersionModel>>> getVersions(String minecraftVersion) async => const Result.success([]);
  @override Future<Result<List<String>>> getLibrariesPath(String id) async => throw UnimplementedError();
  @override Future<Result<void>> install(String id, {String? minecraftVersion, void Function(int, int?)? onProgress}) async => throw UnimplementedError();
  @override Future<Result<bool>> isInstalled(String id) async => throw UnimplementedError();
  @override Future<Result<void>> processInstallation(String id, String minecraftVersion, {String? javaExecutablePath}) async => throw UnimplementedError();
}

class FakeForgeRepository implements ForgeRepository {
  @override String get id => 'forge';
  @override String get name => 'Forge';
  @override String get icon => 'assets/forge.svg';
  @override Future<Result<List<ModLoaderVersionModel>>> getVersions(String minecraftVersion) async => const Result.success([]);
  @override Future<Result<String?>> getLatestVersion(String minecraftVersion) async => const Result.success(null);
  @override Future<Result<String?>> getRecommendedVersion(String minecraftVersion) async => const Result.success(null);
  @override Future<Result<List<String>>> getLibrariesPath(String id) async => throw UnimplementedError();
  @override Future<Result<void>> install(String id, {String? minecraftVersion, void Function(int, int?)? onProgress}) async => throw UnimplementedError();
  @override Future<Result<bool>> isInstalled(String id) async => throw UnimplementedError();
  @override Future<Result<void>> processInstallation(String id, String minecraftVersion, {String? javaExecutablePath}) async => throw UnimplementedError();
}

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
      Provider<List<ModLoaderRepository>>.value(value: [mockFabricRepo, mockForgeRepo]),
      Provider<DownloadService>.value(value: FakeDownloadService()),
      Provider<JavaRepository>.value(value: FakeJavaRepository()),
      Provider<InstanceStylingRepository>.value(value: FakeInstanceStylingRepository()),
      Provider<ToastService>.value(value: ToastService()),
      ChangeNotifierProvider<BreadcrumbService>(create: (_) => BreadcrumbService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider(
          create: (context) => InstanceScreenViewModel(
            instanceRepository: context.read(),
          ),
          child: Consumer<InstanceScreenViewModel>(
            builder: (context, viewModel, _) => InstancesScreen(viewModel: viewModel),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Instance Installation Tests', () {
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

    testWidgets('Test Install Button Triggers Installation', (WidgetTester tester) async { await tester.binding.setSurfaceSize(const Size(1920, 1080)); addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildTestApp(
        mockInstanceRepo: mockInstanceRepo,
        mockMinecraftRepo: mockMinecraftRepo,
        mockFabricRepo: mockFabricRepo,
        mockForgeRepo: mockForgeRepo,
      ));
      
      // Allow InstancesScreenViewModel to load instances
      await tester.pumpAndSettle();

      // The InstanceCard is a "big card" on desktop and hides its buttons until hovered.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      
      final cardFinder = find.byType(InstanceCard);
      await gesture.moveTo(tester.getCenter(cardFinder));
      await tester.pumpAndSettle();

      final installBtn = find.byKey(const ValueKey('instance_install_button_test_instance'));
      expect(installBtn, findsOneWidget, reason: 'Install button should be visible for uninstalled instance');

      await tester.tap(installBtn);
      
      // Wait for the simulated installation to complete
      await tester.pumpAndSettle();

      expect(mockMinecraftRepo.installCalled, isTrue, reason: 'Install method on MinecraftRepository should be called');
      expect(mockMinecraftRepo.installedInstance?.id, 'test_instance', reason: 'Correct instance should be passed to install');
      
      await gesture.removePointer();
    });

    testWidgets('Test Install Button Shows Error Dialog on Failure', (WidgetTester tester) async { await tester.binding.setSurfaceSize(const Size(1920, 1080)); addTearDown(() => tester.binding.setSurfaceSize(null));
      mockMinecraftRepo.shouldFailInstall = true;
      
      await tester.pumpWidget(buildTestApp(
        mockInstanceRepo: mockInstanceRepo,
        mockMinecraftRepo: mockMinecraftRepo,
        mockFabricRepo: mockFabricRepo,
        mockForgeRepo: mockForgeRepo,
      ));
      
      // Allow InstancesScreenViewModel to load instances
      await tester.pumpAndSettle();

      // Hover over card
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      
      final cardFinder = find.byType(InstanceCard);
      await gesture.moveTo(tester.getCenter(cardFinder));
      await tester.pumpAndSettle();

      final installBtn = find.byKey(const ValueKey('instance_install_button_test_instance'));
      expect(installBtn, findsOneWidget);

      await tester.tap(installBtn);
      
      // Wait for the simulated installation to complete and dialog to appear
      await tester.pumpAndSettle();

      expect(mockMinecraftRepo.installCalled, isTrue, reason: 'Install method on MinecraftRepository should be called');
      
      // Verify dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('Test install failure'), findsOneWidget);
      
      // Close the dialog
      final closeBtnFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Button),
      );
      await tester.tap(closeBtnFinder);
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsNothing);

      await gesture.removePointer();
    });
  });
}




