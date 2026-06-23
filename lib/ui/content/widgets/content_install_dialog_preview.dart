import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/content/widgets/content_install_dialog.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/content/content_file.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/api/content_provider.dart';

class _FakeContentProvider implements ContentProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeContentRepo extends ContentRepository {
  _FakeContentRepo() : super(provider: _FakeContentProvider());
}

class _FakeInstanceRepo implements InstanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDownloadService implements DownloadService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@Preview(name: 'Content Install Dialog', group: 'Content')
Widget contentInstallDialogPreview() {
  const item = ContentItem(
    id: 'mock_mod_id',
    slug: 'mock-mod',
    title: 'Awesome Mod',
    description: 'A mock mod for preview',
    projectType: 'mod',
  );

  const version = ContentVersion(
    id: 'mock_version_id',
    projectId: 'mock_mod_id',
    name: '1.0.0',
    versionNumber: '1.0.0',
    gameVersions: ['1.20.1'],
    loaders: ['fabric', 'forge'],
    files: [
      ContentFile(
        url: 'https://example.com/mod.jar',
        filename: 'awesome_mod.jar',
        primary: true,
      ),
    ],
  );

  final viewModel = ContentDetailViewModel(
    item: item,
    contentRepository: _FakeContentRepo(),
    instanceRepository: _FakeInstanceRepo(),
  );

  // Prepopulate instances
  viewModel.instances = [
    InstanceModel(
      id: 'inst1',
      name: 'Fabric 1.20.1',
      minecraftVersion: '1.20.1',
      modLoader: 'fabric',
      modLoaderVersion: '0.15.7',
    ),
    InstanceModel(
      id: 'inst2',
      name: 'Forge 1.20.1',
      minecraftVersion: '1.20.1',
      modLoader: 'forge',
      modLoaderVersion: '47.1.0',
    ),
    InstanceModel(
      id: 'inst3',
      name: 'Vanilla 1.18.2',
      minecraftVersion: '1.18.2',
      modLoader: '',
      modLoaderVersion: '',
    ),
  ];

  return MultiProvider(
    providers: [
      Provider<DownloadService>.value(value: _FakeDownloadService()),
      Provider<InstanceRepository>.value(value: _FakeInstanceRepo()),
    ],
    child: Center(
      child: Material(
        color: Colors.transparent,
        child: ContentInstallDialog(
          viewModel: viewModel,
          version: version,
        ),
      ),
    ),
  );
}

@Preview(name: 'Content Install Dialog (Empty)', group: 'Content')
Widget contentInstallDialogEmptyPreview() {
  const item = ContentItem(
    id: 'mock_mod_id',
    slug: 'mock-mod',
    title: 'Awesome Mod',
    description: 'A mock mod for preview',
    projectType: 'mod',
  );

  const version = ContentVersion(
    id: 'mock_version_id',
    projectId: 'mock_mod_id',
    name: '1.0.0',
    versionNumber: '1.0.0',
    gameVersions: ['1.16.5'], // No compatible instances
    loaders: ['fabric'],
    files: [],
  );

  final viewModel = ContentDetailViewModel(
    item: item,
    contentRepository: _FakeContentRepo(),
    instanceRepository: _FakeInstanceRepo(),
  );

  viewModel.instances = [
    InstanceModel(
      id: 'inst1',
      name: 'Fabric 1.20.1',
      minecraftVersion: '1.20.1',
      modLoader: 'fabric',
      modLoaderVersion: '0.15.7',
    ),
  ];

  return MultiProvider(
    providers: [
      Provider<DownloadService>.value(value: _FakeDownloadService()),
      Provider<InstanceRepository>.value(value: _FakeInstanceRepo()),
    ],
    child: Center(
      child: Material(
        color: Colors.transparent,
        child: ContentInstallDialog(
          viewModel: viewModel,
          version: version,
        ),
      ),
    ),
  );
}
