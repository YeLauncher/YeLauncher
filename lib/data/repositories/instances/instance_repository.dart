import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/utilities/result.dart';

abstract class InstanceRepository {
  Future<List<InstanceModel>> getInstances();
  Future<void> saveInstance(InstanceModel instance);
  Future<void> deleteInstance(String id);
}
