import 'package:mockito/annotations.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';

import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_styling_repository.dart';
import 'package:yelauncher/ui/core/toast/toast_service.dart';
import 'package:yelauncher/ui/core/notification_provider.dart';

@GenerateNiceMocks([
  MockSpec<MinecraftRepository>(),
  MockSpec<ContentRepository>(),
  MockSpec<ModLoaderRepository>(),
  MockSpec<DownloadService>(),
  MockSpec<SettingsRepository>(),
  MockSpec<InstanceRepository>(),
  MockSpec<InstanceStylingRepository>(),
  MockSpec<ToastService>(),
  MockSpec<NotificationProvider>(),
])
void main() {}
