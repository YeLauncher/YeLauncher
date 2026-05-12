import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yelauncher/data/services/api/models/rule_api_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';

/// Service responsible for launching Minecraft instances.
///
/// This extracts the launch / run logic out of the repository layer so that
/// [InstanceRepository] stays a pure data-persistence contract.
class InstanceService {
  final _log = Logger('InstanceService');

  /// Opens the folder containing the instance
  Future<void> openFolder(InstanceModel instance) async {
    final appData = await getApplicationSupportDirectory();
    final gameDir = appData.path; // Game dir is shared for now

    _log.info('Opening folder: $gameDir');

    if (Platform.isWindows) {
      await Process.start('explorer', [gameDir]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [gameDir]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [gameDir]);
    }
  }
}
