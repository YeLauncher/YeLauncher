import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/result.dart';

class ContentDetailViewModel extends ChangeNotifier {
  final ContentRepository _contentRepository;
  final InstanceRepository _instanceRepository;
  final ContentItem item;
  ContentItem? fullItem;

  ContentDetailViewModel({
    required this.item,
    required ContentRepository contentRepository,
    required InstanceRepository instanceRepository,
  })  : _contentRepository = contentRepository,
        _instanceRepository = instanceRepository;

  bool isLoading = true;
  List<ContentVersion> versions = [];
  List<InstanceModel> instances = [];

  Future<void> loadDetails() async {
    isLoading = true;
    notifyListeners();

    // Fetch full project details to get gallery, downloads, etc.
    final itemResult = await _contentRepository.getContent(item.id);
    if (itemResult is Success<ContentItem>) {
      fullItem = itemResult.value;
    }

    final result = await _contentRepository.getVersions(item.id);
    if (result is Success<List<ContentVersion>>) {
      versions = result.value;
    }
    
    final instancesResult = await _instanceRepository.getInstances();
    instances = instancesResult;

    isLoading = false;
    notifyListeners();
  }

  List<InstanceModel> getCompatibleInstances(ContentVersion version) {
    if (item.projectType == 'modpack') {
      return [];
    }

    return instances.where((inst) {
      if (!version.gameVersions.contains(inst.minecraftVersion)) return false;
      
      if (item.projectType == 'mod') {
        final loaderLower = inst.modLoader.toLowerCase();
        if (loaderLower.isEmpty || loaderLower == 'none' || loaderLower == 'vanilla') {
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
}
