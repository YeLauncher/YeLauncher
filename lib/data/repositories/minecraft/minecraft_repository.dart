import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_process_model.dart';

import 'package:yelauncher/utilities/result.dart';

abstract class MinecraftRepository {
  Future<Result<List<MinecraftProfileModel>>> getProfiles();
  Future<Result<MinecraftProfileModel?>> getSelectedProfile();
  Future<Result<void>> selectProfile(String uuid);
  Future<Result<void>> removeProfile(String uuid);
  Future<Result<MinecraftProfileModel>> authenticate();
  Future<Result<void>> addOfflineProfile(String nickname);
  void cancelAuthentication();
  Future<Result<List<MinecraftVersionModel>>> getVersions();
  Future<Result<void>> install(
    InstanceModel instance, {
    void Function(int, int?)? onProgress,
    void Function(String)? onStepChanged,
  });
  Future<Result<bool>> isInstalled(InstanceModel instance);
  Future<Result<String>> getJavaVersion(String id);
  Future<Result<MinecraftProcessModel>> run(InstanceModel instance);
  Future<bool> isAuthenticated();
  Future<Result<void>> logout(); // Logs out the currently selected profile
}
