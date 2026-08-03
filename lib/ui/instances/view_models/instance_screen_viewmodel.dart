import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/command.dart';
import 'package:yelauncher/utilities/result.dart';

enum InstanceSortOrder {
  lastPlayed,
  nameAsc,
  nameDesc,
}

class InstanceScreenViewModel extends ChangeNotifier {
  final InstanceRepository _instanceRepository;

  List<InstanceModel> instances = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;

  final Set<String> _selectedInstanceIds = {};
  Set<String> get selectedInstanceIds => _selectedInstanceIds;

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedInstanceIds.clear();
    }
    notifyListeners();
  }

  void toggleInstanceSelection(String id) {
    if (_selectedInstanceIds.contains(id)) {
      _selectedInstanceIds.remove(id);
    } else {
      _selectedInstanceIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedInstanceIds.clear();
    _selectedInstanceIds.addAll(instances.map((e) => e.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedInstanceIds.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedInstances() async {
    for (final id in _selectedInstanceIds) {
      await _instanceRepository.deleteInstance(id);
    }
    _selectedInstanceIds.clear();
    _isSelectionMode = false;
    await _loadInstances();
  }

  InstanceSortOrder _sortOrder = InstanceSortOrder.lastPlayed;
  InstanceSortOrder get sortOrder => _sortOrder;
  set sortOrder(InstanceSortOrder value) {
    _sortOrder = value;
    notifyListeners();
  }

  List<InstanceModel> get filteredAndSortedInstances {
    var result = List<InstanceModel>.from(instances);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((i) => i.name.toLowerCase().contains(query)).toList();
    }

    result.sort((a, b) {
      switch (_sortOrder) {
        case InstanceSortOrder.lastPlayed:
          if (a.lastPlayed == null && b.lastPlayed == null) return 0;
          if (a.lastPlayed == null) return 1;
          if (b.lastPlayed == null) return -1;
          return b.lastPlayed!.compareTo(a.lastPlayed!);
        case InstanceSortOrder.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case InstanceSortOrder.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    });

    return result;
  }

  late final Command0 loadInstances;

  InstanceScreenViewModel({required InstanceRepository instanceRepository})
    : _instanceRepository = instanceRepository {
    loadInstances = Command0(_loadInstances);
  }

  Future<Result<void>> _loadInstances() async {
    instances = await _instanceRepository.getInstances();
    if (selectedInstanceForDrawer != null) {
      selectedInstanceForDrawer = instances
          .where((i) => i.id == selectedInstanceForDrawer!.id)
          .firstOrNull;
    }
    notifyListeners();
    return const Result.success(null);
  }

  Future<void> installOrRunInstance(InstanceModel instance) async {}

  InstanceModel? selectedInstanceForDrawer;

  Future<void> openDrawer(InstanceModel instance) async {
    await _loadInstances();
    selectedInstanceForDrawer = instances
        .where((i) => i.id == instance.id)
        .firstOrNull ?? instance;
    notifyListeners();
  }

  void closeDrawer() {
    selectedInstanceForDrawer = null;
    notifyListeners();
  }
}
