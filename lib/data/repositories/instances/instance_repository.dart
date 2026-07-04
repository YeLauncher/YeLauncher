import 'package:yelauncher/domain/models/instance/instance_model.dart';

abstract class InstanceRepository {
  Future<List<InstanceModel>> getInstances();
  Future<void> saveInstance(InstanceModel instance);
  Future<void> deleteInstance(String id);
  Future<void> openFolder(InstanceModel instance);
  Future<void> createInstance(InstanceModel instance);
}
