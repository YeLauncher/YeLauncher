import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instance_drawer.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/text_field.dart' as ye_text_field;

class FakeSettingsRepository extends ChangeNotifier implements SettingsRepository {
  @override Locale get currentLocale => const Locale('en');
  @override int get javaMemory => 4096;
  @override int get windowWidth => 854;
  @override int get windowHeight => 480;
  @override String get customJavaPath => '';
  @override String get jvmArguments => '';

  @override Future<void> init() async {}
  @override Future<void> setLocale(Locale locale) async {}
  @override Future<void> setMinecraftSettings({
    required int javaMemory,
    required int windowWidth,
    required int windowHeight,
    required String customJavaPath,
    required String jvmArguments,
  }) async {}
}

class FakeInstanceRepository implements InstanceRepository {
  final List<InstanceModel> _instances = [
    InstanceModel(
      id: 'test_instance',
      name: 'Original Name',
      icon: 'assets/grass_block.png',
      color: '0xFF4CAF50',
      minecraftVersion: '1.20.1',
      modLoader: 'vanilla',
      modLoaderVersion: '',
      isInstalled: true,
    ),
  ];

  @override Future<List<InstanceModel>> getInstances() async => _instances;
  
  @override Future<void> saveInstance(InstanceModel instance) async {
    final index = _instances.indexWhere((i) => i.id == instance.id);
    if (index != -1) {
      _instances[index] = instance;
    }
  }
  
  @override Future<void> deleteInstance(String id) async {
    _instances.removeWhere((i) => i.id == id);
  }
  
  @override Future<void> openFolder(InstanceModel instance) async {}
  @override Future<void> openLogsFolder(InstanceModel instance) async {}
  @override Future<void> createInstance(InstanceModel instance) async {}
}

Widget buildTestApp({
  required InstanceModel instance,
  required InstanceRepository mockInstanceRepo,
  required SettingsRepository mockSettingsRepo,
  required InstanceScreenViewModel mockScreenViewModel,
}) {
  return MultiProvider(
    providers: [
      Provider<InstanceRepository>.value(value: mockInstanceRepo),
      ChangeNotifierProvider<SettingsRepository>.value(value: mockSettingsRepo),
      ChangeNotifierProvider<InstanceScreenViewModel>.value(value: mockScreenViewModel),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: InstanceDrawer(instance: instance),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Instance Drawer Integration Tests', () {
    late FakeInstanceRepository mockInstanceRepo;
    late FakeSettingsRepository mockSettingsRepo;
    late InstanceScreenViewModel screenViewModel;

    setUp(() {
      mockInstanceRepo = FakeInstanceRepository();
      mockSettingsRepo = FakeSettingsRepository();
      screenViewModel = InstanceScreenViewModel(instanceRepository: mockInstanceRepo);
    });

    testWidgets('Can change instance name and save', (WidgetTester tester) async { await tester.binding.setSurfaceSize(const Size(1920, 1080)); addTearDown(() => tester.binding.setSurfaceSize(null));
      final initialInstances = await mockInstanceRepo.getInstances();
      final targetInstance = initialInstances.first;

      await tester.pumpWidget(buildTestApp(
        instance: targetInstance,
        mockInstanceRepo: mockInstanceRepo,
        mockSettingsRepo: mockSettingsRepo,
        mockScreenViewModel: screenViewModel,
      ));

      await tester.pumpAndSettle();

      // Ensure drawer is showing correct name
      expect(find.text('Original Name'), findsWidgets);

      // Find the TextField for the name.
      final editableTextFinder = find.byType(ye_text_field.TextField).first;
      expect(editableTextFinder, findsOneWidget);

      await tester.enterText(editableTextFinder, 'New Awesome Name');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.widgetWithText(Button, 'Save Changes'));
      await tester.pumpAndSettle();

      // Verify repository updated
      final updatedInstances = await mockInstanceRepo.getInstances();
      expect(updatedInstances.first.name, 'New Awesome Name');
    });

    testWidgets('Can delete instance', (WidgetTester tester) async { await tester.binding.setSurfaceSize(const Size(1920, 1080)); addTearDown(() => tester.binding.setSurfaceSize(null));
      final initialInstances = await mockInstanceRepo.getInstances();
      final targetInstance = initialInstances.first;

      await tester.pumpWidget(buildTestApp(
        instance: targetInstance,
        mockInstanceRepo: mockInstanceRepo,
        mockSettingsRepo: mockSettingsRepo,
        mockScreenViewModel: screenViewModel,
      ));

      await tester.pumpAndSettle();

      // Scroll to and tap Delete button
      final deleteBtnFinder = find.widgetWithText(Button, 'Delete').first;
      await tester.ensureVisible(deleteBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Delete in confirmation dialog
      final confirmDeleteBtnFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(Button, 'Delete'),
      );
      await tester.tap(confirmDeleteBtnFinder);
      await tester.pumpAndSettle();

      // Verify repository updated
      final remainingInstances = await mockInstanceRepo.getInstances();
      expect(remainingInstances.isEmpty, isTrue);
    });

    testWidgets('Can change window resolution and RAM', (WidgetTester tester) async { await tester.binding.setSurfaceSize(const Size(1920, 1080)); addTearDown(() => tester.binding.setSurfaceSize(null));
      final initialInstances = await mockInstanceRepo.getInstances();
      // Need to re-insert the deleted instance because tests might share state or we can just run this test first
      // Actually `setUp` creates a new `FakeInstanceRepository` and `FakeSettingsRepository` each time.
      final targetInstance = initialInstances.first;

      await tester.pumpWidget(buildTestApp(
        instance: targetInstance,
        mockInstanceRepo: mockInstanceRepo,
        mockSettingsRepo: mockSettingsRepo,
        mockScreenViewModel: screenViewModel,
      ));

      await tester.pumpAndSettle();

      // Find TextFields by type and index (0: Name, 1: Width, 2: Height)
      final widthFieldFinder = find.byType(ye_text_field.TextField).at(1);
      final heightFieldFinder = find.byType(ye_text_field.TextField).at(2);
      
      // Ensure they are visible
      await tester.ensureVisible(widthFieldFinder);
      await tester.pumpAndSettle();
      
      // Enter resolution
      await tester.enterText(widthFieldFinder, '1280');
      await tester.enterText(heightFieldFinder, '720');
      await tester.pumpAndSettle();
      
      // Find and click "Override global setting"
      final overrideFinder = find.text('Override global setting');
      await tester.ensureVisible(overrideFinder);
      await tester.pumpAndSettle();
      await tester.tap(overrideFinder);
      await tester.pumpAndSettle();

      // At this point, the AppSlider should be visible. We don't strictly need to move it, 
      // but just tapping on it sets a value, or we can just leave it as it defaults to the global value overridden.
      // Wait, let's just make sure it's saved correctly. The initial slider value is the global setting (4096).
      // We can also just tap the Save button now.
      
      final saveBtnFinder = find.widgetWithText(Button, 'Save Changes');
      await tester.ensureVisible(saveBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();
      
      // Verify repository updated
      final updatedInstances = await mockInstanceRepo.getInstances();
      final updatedInstance = updatedInstances.first;
      expect(updatedInstance.windowWidth, 1280);
      expect(updatedInstance.windowHeight, 720);
      expect(updatedInstance.javaMemory, 4096); // Defaults to global memory
    });
  });
}
