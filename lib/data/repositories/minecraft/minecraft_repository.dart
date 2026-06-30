import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';

import 'package:yelauncher/utilities/result.dart';

abstract class MinecraftRepository {
  Future<Result<MinecraftProfileModel>> getProfile();
  Future<Result<MinecraftProfileModel>> authenticate();
  void cancelAuthentication();
  Future<Result<MinecraftProfileModel>> authenticateOffline(String username);
  Future<Result<List<MinecraftVersionModel>>> getVersions();
  Future<Result<void>> install(
    InstanceModel instance, {
    void Function(int, int?)? onProgress,
  });
  Future<Result<bool>> isInstalled(InstanceModel instance);
  Future<Result<String>> getJavaVersion(String id);
  Future<Result<MinecraftProcessModel>> run(InstanceModel instance);
  Future<bool> isAuthenticated();
  Future<Result<void>> logout();
}
