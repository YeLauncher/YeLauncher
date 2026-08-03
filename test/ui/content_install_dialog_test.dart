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
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_install_dialog.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
    print('setUp started');
    mockInstanceRepository = MockInstanceRepository();
    mockDownloadService = MockDownloadService();
    mockContentRepository = MockContentRepository();
    
    print('creating temp dir');
    tempDir = await Directory.systemTemp.createTemp('yelauncher_test_');
    print('setting path provider instance');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    print('setUp finished');
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
          body: ContentInstallDialog(
            viewModel: viewModel,
            version: version,
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

    when(mockInstanceRepository.getInstances())
        .thenAnswer((_) async => [existingInstance]);
    when(mockInstanceRepository.saveInstance(any)).thenAnswer((_) async {});
    provideDummy<Result<void>>(const Result<void>.success(null));
    when(mockDownloadService.downloadIfMissing(any))
        .thenAnswer((_) async => const Result.success(null));

    // Create view model and new version
    final item = ContentItem(
      id: projectId,
      slug: 'test-mod',
      title: 'Test Mod',
      description: 'Test mod description',
      projectType: 'mod',
    );
    
    final newVersion = ContentVersion(
      id: 'ver2',
      projectId: projectId,
      name: 'Test Mod 2.0',
      versionNumber: '2.0',
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
      item: item,
      contentRepository: mockContentRepository,
      instanceRepository: mockInstanceRepository,
    );
    viewModel.instances = [existingInstance];

    await tester.pumpWidget(createTestWidget(viewModel, newVersion));
    await tester.pump();

    // Select the instance
    await tester.tap(find.text('Test Instance'));
    await tester.pump();

    // Click Install and wait for real async I/O to complete
    await tester.runAsync(() async {
      await tester.tap(find.text('Install'));
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
