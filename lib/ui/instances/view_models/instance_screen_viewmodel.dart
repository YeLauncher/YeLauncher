import 'package:flutter/foundation.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/command.dart';
import 'package:yelauncher/utilities/result.dart';

class InstanceScreenViewModel extends ChangeNotifier {
  final InstanceRepository _instanceRepository;

  List<InstanceModel> instances = [];

  late final Command0 loadInstances;

  InstanceScreenViewModel({required InstanceRepository instanceRepository})
    : _instanceRepository = instanceRepository {
    loadInstances = Command0(_loadInstances);
  }

  Future<Result<void>> _loadInstances() async {
    instances = await _instanceRepository.getInstances();
    notifyListeners();
    return const Result.success(null);
  }

  Future<void> installOrRunInstance(InstanceModel instance) async {}
}
