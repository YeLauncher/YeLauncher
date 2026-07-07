import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/config/dependencies.dart';

import 'package:yelauncher/data/services/secure_storage_service.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';

import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL; // Set the logging level to capture all logs

  final secureStorage = SecureStorageService();
  final profile = MinecraftProfileModel(
    nickname: 'TestAccount',
    uuid: '00000000-0000-0000-0000-000000000000',
    accessToken: 'dummy-token',
    userType: 'mojang',
  );
  await secureStorage.saveProfiles([profile]);
  await secureStorage.saveSelectedProfileId(profile.uuid);

  runApp(
    MultiProvider(providers: providersLocal, child: const YeLauncherApp()),
  );
}
