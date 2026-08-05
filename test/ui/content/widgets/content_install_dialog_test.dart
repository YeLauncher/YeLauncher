import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/domain/models/content/content_file.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_install_dialog.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

import 'content_install_dialog_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<InstanceRepository>(),
  MockSpec<ContentRepository>(),
  MockSpec<DownloadService>(),
])
void main() {
  late MockInstanceRepository mockInstanceRepo;
  late MockContentRepository mockContentRepo;
  late MockDownloadService mockDownloadService;
  late ContentDetailViewModel viewModel;

  final testItem = ContentItem(
    id: 'test_project',
    slug: 'test-project',
    title: 'Test Mod',
    description: 'A test mod',
    projectType: 'mod',
    iconUrl: null,
    downloads: 100,
    organization: null,
    teamId: null,
    author: 'Tester',
    loaders: ['fabric'],
    gameVersions: ['1.20.1'],
    gallery: null,
  );

  final testVersion = ContentVersion(
    id: 'test_version',
    projectId: 'test_project',
    name: 'Test Version',
    versionNumber: '1.0.0',
    versionType: 'release',
    gameVersions: ['1.20.1'],
    loaders: ['fabric'],
    files: [
      ContentFile(
        url: 'http://example.com/mod.jar',
        filename: 'mod.jar',
        primary: true,
      )
    ],
  );

  final testInstance = InstanceModel(
    id: 'test_instance',
    name: 'Test Instance',
    minecraftVersion: '1.20.1',
    modLoader: 'fabric',
    modLoaderVersion: '0.14.22',
    installedContent: [],
    customJavaPath: '',
    jvmArguments: '',
    javaMemory: 2048,
    windowWidth: 854,
    windowHeight: 480,
  );

  setUp(() {
    mockInstanceRepo = MockInstanceRepository();
    mockContentRepo = MockContentRepository();
    mockDownloadService = MockDownloadService();

    viewModel = ContentDetailViewModel(
      item: testItem,
      contentRepository: mockContentRepo,
      instanceRepository: mockInstanceRepo,
    );
    // Pretend instances were loaded in the view model initially
    viewModel.instances = [testInstance];
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        Provider<InstanceRepository>.value(value: mockInstanceRepo),
        Provider<ContentRepository>.value(value: mockContentRepo),
        Provider<DownloadService>.value(value: mockDownloadService),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ContentInstallDialog(
                      viewModel: viewModel,
                      targetVersion: testVersion,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('installation is available after deleting content', (tester) async {
    // 1. Simulate that the instance NO LONGER has the content (it was deleted)
    // Initially, let's say the view model somehow still holds the old data where it was installed?
    // The test case is: the instance has NO content, meaning it should be available.
    // Even if viewmodel had it, the dialog will fetch from repository!
    when(mockInstanceRepo.getInstances()).thenAnswer((_) async => [testInstance]);

    await tester.pumpWidget(buildTestWidget());
    
    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Test Instance'));
    await tester.pump();

    // Verify dialog opened and the Install button is shown because the content is not installed
    expect(find.text('Install'), findsOneWidget);

    // 2. Now simulate that the instance HAS the content
    final instanceWithContent = testInstance.copyWith(
      installedContent: [
        InstalledContentModel(
          projectId: 'test_project',
          versionId: 'test_version',
          filename: 'mod.jar',
          title: 'Test Mod',
          type: 'mod',
        ),
      ],
    );

    when(mockInstanceRepo.getInstances()).thenAnswer((_) async => [instanceWithContent]);

    // Actually we can just pop the navigator
    Navigator.of(tester.element(find.byType(ContentInstallDialog))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Test Instance'));
    await tester.pump();

    // Verify it says "Already Installed"
    expect(find.text('Already Installed'), findsOneWidget);

    // 3. Delete the content (revert to testInstance without content)
    when(mockInstanceRepo.getInstances()).thenAnswer((_) async => [testInstance]);

    Navigator.of(tester.element(find.byType(ContentInstallDialog))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Reopen dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Test Instance'));
    await tester.pump();

    // Verify it says "Install" again!
    expect(find.text('Install'), findsOneWidget);
  });
}
