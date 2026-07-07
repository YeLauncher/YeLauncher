import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/instance_service.dart';
import 'package:yelauncher/data/services/minecraft_service.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';

/// Persistent [InstanceRepository] backed by individual JSON files.
///
/// Each instance is stored as `<id>.json` inside the
/// `<appSupportDir>/instances/` directory.
class InstanceRepositoryLocal implements InstanceRepository {
  final _log = Logger('InstanceRepositoryLocal');
  final InstanceService _instanceService;

  InstanceRepositoryLocal({
    required InstanceService instanceService,
    required MinecraftService minecraftService,
  }) : _instanceService = instanceService;

  /// Returns the `instances/` directory inside the app support folder,
  /// creating it if it does not exist.
  Future<Directory> _instancesDir() async {
    final appData = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appData.path, 'instances'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the [File] for the given instance [id].
  Future<File> _fileFor(String id) async {
    final dir = await _instancesDir();
    return File(p.join(dir.path, '$id.json'));
  }

  /// Writes an [InstanceModel] to its JSON file.
  Future<void> _writeInstance(InstanceModel instance) async {
    final file = await _fileFor(instance.id);
    final json = const JsonEncoder.withIndent('  ').convert(instance.toJson());
    await file.writeAsString(json);
  }

  /// Reads a single JSON file and deserializes it into an [InstanceModel].
  /// Returns `null` when the file cannot be parsed.
  Future<InstanceModel?> _readInstance(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return InstanceModel.fromJson(json);
    } catch (e) {
      _log.warning('Failed to read instance from ${file.path}: $e');
      return null;
    }
  }

  @override
  Future<List<InstanceModel>> getInstances() async {
    final dir = await _instancesDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    final instances = <InstanceModel>[];
    for (final file in files) {
      final instance = await _readInstance(file);
      if (instance != null) {
        instances.add(instance);
      }
    }
    return instances;
  }

  @override
  Future<void> saveInstance(InstanceModel instance) async {
    await _writeInstance(instance);
    _log.info('Created instance "${instance.name}" (${instance.id})');
  }

  @override
  Future<void> deleteInstance(String id) async {
    final file = await _fileFor(id);
    if (await file.exists()) {
      await file.delete();
      _log.info('Deleted instance $id');
    }
  }

  @override
  Future<void> openFolder(InstanceModel instance) async {
    await _instanceService.openFolder(instance);
  }

  @override
  Future<void> createInstance(InstanceModel instance) async {
    await saveInstance(instance);
  }
}
