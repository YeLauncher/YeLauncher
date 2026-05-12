import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

abstract class MinecraftRepository {
  Future<Result<List<MinecraftVersionModel>>> getVersions();

  Future<Result<void>> install(String id);

  Future<Result<String>> getJavaVersion(String id);

  Future<Result<bool>> isInstalled(String id);
}
