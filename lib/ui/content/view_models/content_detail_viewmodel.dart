import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:logging/logging.dart';

import 'package:yelauncher/routing/breadcrumb_service.dart';

class ContentDetailViewModel extends ChangeNotifier {
  final _log = Logger('ContentDetailViewModel');
  final ContentRepository _contentRepository;
  final InstanceRepository _instanceRepository;
  final BreadcrumbService _breadcrumbService;
  
  final String id;
  ContentItem? _item;
  ContentItem? fullItem;

  ContentItem get item => _item ?? ContentItem(id: id, slug: id, title: 'Loading...', description: '', projectType: 'mod');

  ContentDetailViewModel({
    required this.id,
    ContentItem? initialItem,
    required ContentRepository contentRepository,
    required InstanceRepository instanceRepository,
    required BreadcrumbService breadcrumbService,
  })  : _contentRepository = contentRepository,
        _instanceRepository = instanceRepository,
        _breadcrumbService = breadcrumbService,
        _item = initialItem {
    if (_item != null) {
      _breadcrumbService.registerTitle(id, _item!.title);
    }
  }

  bool isLoading = true;
  List<ContentVersion> versions = [];
  List<InstanceModel> instances = [];
  List<ContentItem> dependencies = [];

  Future<void> loadDetails() async {
    // Fetch full project details to get gallery, downloads, etc.
    final itemResult = await _contentRepository.getContent(id);
    if (itemResult is Success<ContentItem>) {
      fullItem = itemResult.value;
      _item ??= fullItem;
      _breadcrumbService.registerTitle(id, fullItem!.title);
    }

    final result = await _contentRepository.getVersions(id);
    if (result is Success<List<ContentVersion>>) {
      versions = result.value;
    }
    
    final depsResult = await _contentRepository.getProjectDependencies(id);
    if (depsResult is Success<List<ContentItem>>) {
      dependencies = depsResult.value;
    }

    final instancesResult = await _instanceRepository.getInstances();
    instances = instancesResult;

    isLoading = false;
    notifyListeners();
  }

  List<InstanceModel> getCompatibleInstances(ContentVersion version) {
    _log.info('getCompatibleInstances: instances=${instances.length}, gameVersions=${version.gameVersions}');
    if (item.projectType == 'modpack') {
      return [];
    }

    return instances.where((inst) {
      _log.info('Checking instance: ${inst.name} (${inst.minecraftVersion}, ${inst.modLoader})');
      if (!version.gameVersions.contains(inst.minecraftVersion)) return false;
      
      if (item.projectType == 'mod') {
        final loaderLower = inst.modLoader.toLowerCase();
        if (loaderLower.isEmpty || loaderLower == 'none' || loaderLower == 'vanilla') {
          _log.info('Rejecting instance: ${inst.name} because it is vanilla');
          return false;
        }

        bool loaderMatch = version.loaders.contains(loaderLower);
        
        // Allow Quilt instances to load Fabric mods
        if (loaderLower == 'quilt' && version.loaders.contains('fabric')) {
          loaderMatch = true;
        }

        if (!loaderMatch) return false;
      }
      return true;
    }).toList();
  }

  ContentVersion? getBestVersionForInstance(InstanceModel instance) {
    if (item.projectType == 'modpack') return null;

    for (final v in versions) {
      if (!v.gameVersions.contains(instance.minecraftVersion)) continue;
      
      if (item.projectType == 'mod') {
        final loaderLower = instance.modLoader.toLowerCase();
        if (loaderLower.isEmpty || loaderLower == 'none' || loaderLower == 'vanilla') continue;
        
        bool loaderMatch = v.loaders.contains(loaderLower);
        if (loaderLower == 'quilt' && v.loaders.contains('fabric')) {
          loaderMatch = true;
        }
        if (!loaderMatch) continue;
      }
      return v;
    }
    return null;
  }
}
