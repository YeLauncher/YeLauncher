import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/utilities/result.dart';

import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:logging/logging.dart';

class ContentScreenViewModel extends ChangeNotifier {
  final ContentRepository _contentRepository;
  final MinecraftRepository _minecraftRepository;
  final _log = Logger('ContentScreenViewModel');

  ContentScreenViewModel({
    required ContentRepository contentRepository,
    required MinecraftRepository minecraftRepository,
  })  : _contentRepository = contentRepository,
        _minecraftRepository = minecraftRepository {
    _fetchVersions();
  }

  List<ContentItem> items = [];
  bool isLoading = true;
  bool isLoadingMore = false; // Tracks pagination loading state
  bool hasMoreData = true;     // Flag to prevent useless API calls

  String projectType = 'mod';
  String query = '';
  
  bool showSnapshots = false;
  
  List<String> selectedVersions = [];
  List<String> selectedModLoaders = [];
  List<String> selectedCategories = [];
  String sortOrder = 'relevance';

  List<String> availableVersions = [];
  
  // Modrinth popular categories
  final List<String> availableCategories = [
    'adventure', 'magic', 'technology', 'optimization', 'utility', 'decoration', 'worldgen'
  ];
  
  final List<String> availableModLoaders = ['forge', 'fabric'];

  int _offset = 0;
  final int _limit = 20;

  // Initial fresh search/filter change
  Future<void> search() async {
    isLoading = true;
    isLoadingMore = false;
    hasMoreData = true;
    _offset = 0;
    items = [];
    notifyListeners();

    final result = await _contentRepository.searchContent(
      query: query,
      projectType: projectType,
      versions: selectedVersions,
      modLoaders: selectedModLoaders,
      categories: selectedCategories,
      sortOrder: sortOrder,
      limit: _limit,
      offset: _offset,
    );

    isLoading = false;
    if (result is Success<List<ContentItem>>) {
      items = result.value;
      // If retrieved items are less than the limit, no more data is available
      if (result.value.length < _limit) {
        hasMoreData = false;
      }
    } else {
      items = [];
      hasMoreData = false;
    }

    isLoading = false;
    notifyListeners();
  }

  // Requests the next batch of elements when scrolling down
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMoreData) return;

    isLoadingMore = true;
    notifyListeners();

    _offset = items.length; // Dynamic update based on currently fetched items

    final result = await _contentRepository.searchContent(
      query: query,
      projectType: projectType,
      versions: selectedVersions,
      modLoaders: selectedModLoaders,
      categories: selectedCategories,
      sortOrder: sortOrder,
      limit: _limit,
      offset: _offset,
    );

    if (result is Success<List<ContentItem>>) {
      final newItems = result.value;
      items.addAll(newItems);

      if (newItems.length < _limit) {
        hasMoreData = false;
      }
    } else {
      hasMoreData = false;
    }

    isLoadingMore = false;
    notifyListeners();
  }

  void setProjectType(String type) {
    if (projectType != type) {
      projectType = type;
      // Reset loader filter if switching to a type that doesn't use it
      if (type != 'mod' && type != 'modpack') {
        selectedModLoaders = [];
      }
      search();
    }
  }

  void setQuery(String newQuery) {
    if (query != newQuery) {
      query = newQuery;
      search();
    }
  }

  void toggleVersion(String version) {
    if (selectedVersions.contains(version)) {
      selectedVersions.remove(version);
    } else {
      selectedVersions.add(version);
    }
    search();
  }

  void toggleModLoader(String modLoader) {
    if (selectedModLoaders.contains(modLoader)) {
      selectedModLoaders.remove(modLoader);
    } else {
      selectedModLoaders.add(modLoader);
    }
    search();
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    search();
  }

  void toggleShowSnapshots(bool value) {
    if (showSnapshots != value) {
      showSnapshots = value;
      // Re-fetch or re-filter available versions based on snapshots toggle
      _filterVersions();
    }
  }

  void setSortOrder(String sort) {
    if (sortOrder != sort) {
      sortOrder = sort;
      search();
    }
  }

  List<MinecraftVersionModel> _allMinecraftVersions = [];

  Future<void> _fetchVersions() async {
    final result = await _minecraftRepository.getVersions();
    if (result is Success<List<MinecraftVersionModel>>) {
      _allMinecraftVersions = result.value;
      _filterVersions();
    } else {
      _log.warning('Failed to load Minecraft versions for content filters');
    }
  }

  void _filterVersions() {
    availableVersions = _allMinecraftVersions
        .where((v) => showSnapshots || v.type == 'release')
        .map((v) => v.id)
        .toList();
        
    // Clean up selected versions if they are no longer available
    selectedVersions.removeWhere((v) => !availableVersions.contains(v));
    notifyListeners();
  }
}