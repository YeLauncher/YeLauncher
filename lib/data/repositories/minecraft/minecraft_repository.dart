import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

abstract class MinecraftRepository {
  Future<Result<MinecraftProfileModel>> getProfile();
  Future<Result<MinecraftProfileModel>> authenticate();
  Future<Result<MinecraftProfileModel>> authenticateOffline(String username);
  Future<Result<List<MinecraftVersionModel>>> getVersions();
  Future<Result<void>> install(String id, {void Function(int, int?)? onProgress});
  Future<Result<bool>> isInstalled(String id);
  Future<Result<String>> getJavaVersion(String id);
  Future<Result<void>> run(String id);
  Future<bool> isAuthenticated();
  Future<Result<void>> logout();
}
