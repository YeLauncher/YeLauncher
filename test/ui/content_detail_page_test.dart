import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/routing/breadcrumb_service.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/pages/content_detail_page.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:yelauncher/ui/core/button.dart';

import '../integration_mocks.mocks.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;

  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  late MockInstanceRepository mockInstanceRepository;
  late MockDownloadService mockDownloadService;
  late MockContentRepository mockContentRepository;
  late Directory tempDir;

  setUp(() async {
    mockInstanceRepository = MockInstanceRepository();
    mockDownloadService = MockDownloadService();
    mockContentRepository = MockContentRepository();
    
    tempDir = await Directory.systemTemp.createTemp('yelauncher_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget createTestWidget(ContentDetailViewModel viewModel, ContentVersion version) {
    return MultiProvider(
      providers: [
        Provider<InstanceRepository>.value(value: mockInstanceRepository),
        Provider<DownloadService>.value(value: mockDownloadService),
        Provider<ContentRepository>.value(value: mockContentRepository),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              height: 2000,
              child: ContentDetailPage(
                viewModel: viewModel,
                targetVersion: version,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('updates mod by deleting old jar and replacing in installedContent', (WidgetTester tester) async {
    final oldVersionJarName = 'test_mod-1.0.jar';
    final newVersionJarName = 'test_mod-2.0.jar';
    final projectId = 'proj123';
    
    final instanceId = 'test_instance_id';
    
    // Setup existing instance with old version
    final existingInstance = InstanceModel(
      id: instanceId,
      name: 'Test Instance',
      minecraftVersion: '1.20.1',
      modLoader: 'forge',
      modLoaderVersion: '47.1.3',
      isInstalled: true,
      lastPlayed: DateTime.now(),
      installedContent: [
        InstalledContentModel(
          projectId: projectId,
          versionId: 'ver1',
          filename: oldVersionJarName,
          title: 'Test Mod',
          type: 'mod',
        ),
      ],
    );
    
    // Create the old jar file on disk
    final modDir = Directory(p.join(tempDir.path, 'instances', instanceId, 'mods'));
    modDir.createSync(recursive: true);
    final oldJarFile = File(p.join(modDir.path, oldVersionJarName));
    oldJarFile.writeAsStringSync('old jar content');

    final item = ContentItem(
      id: projectId,
      slug: 'test-mod',
      title: 'Test Mod',
      description: 'Test mod description',
      projectType: 'mod',
    );

    provideDummy<Result<void>>(const Result<void>.success(null));
    provideDummy<Result<ContentItem>>(Result.success(item));
    provideDummy<Result<List<ContentVersion>>>(const Result.success([]));
    provideDummy<Result<List<ContentItem>>>(const Result.success([]));

    when(mockInstanceRepository.getInstances())
        .thenAnswer((_) async => [existingInstance]);
    when(mockInstanceRepository.saveInstance(any)).thenAnswer((_) async {});
    when(mockDownloadService.downloadIfMissing(any, onProgress: anyNamed('onProgress')))
        .thenAnswer((_) async => const Result.success(null));
    
    when(mockContentRepository.getContent(any))
        .thenAnswer((_) async => Result.success(item));
    when(mockContentRepository.getVersions(any))
        .thenAnswer((_) async => const Result.success([]));
    when(mockContentRepository.getProjectDependencies(any))
        .thenAnswer((_) async => const Result.success([]));

    final newVersion = ContentVersion(
      id: 'ver2',
      projectId: projectId,
      name: 'Test Mod 2.0',
      versionNumber: '2.0',
      versionType: 'release',
      gameVersions: ['1.20.1'],
      loaders: ['forge'],
      dependencies: [],
      files: [
        ContentFile(
          url: 'https://example.com/$newVersionJarName',
          filename: newVersionJarName,
          primary: true,
        ),
      ],
    );

    final viewModel = ContentDetailViewModel(
      id: item.id,
      initialItem: item,
      breadcrumbService: BreadcrumbService(),
      contentRepository: mockContentRepository,
      instanceRepository: mockInstanceRepository,
    );
    viewModel.instances = [existingInstance];
    viewModel.isLoading = false;
    viewModel.fullItem = item;
    viewModel.versions = [newVersion];

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    await tester.pumpWidget(createTestWidget(viewModel, newVersion));
    await tester.pump();

    // Select the instance
    await tester.tap(find.text('Test Instance'));
    await tester.pump();

    // Click Install and wait for real async I/O to complete
    await tester.runAsync(() async {
      final button = find.widgetWithText(Button, 'Install');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    // Verify instance was saved with new content
    final captured = verify(mockInstanceRepository.saveInstance(captureAny)).captured;
    expect(captured.length, 1);
    
    final savedInstance = captured.first as InstanceModel;
    expect(savedInstance.installedContent.length, 1);
    expect(savedInstance.installedContent.first.projectId, projectId);
    expect(savedInstance.installedContent.first.filename, newVersionJarName);
    
    // Verify old jar was deleted
    expect(oldJarFile.existsSync(), isFalse);
  });
}
