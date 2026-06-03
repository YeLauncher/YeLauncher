import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

abstract class ModLoaderRepository {
  String get id;
  String get name;
  String get icon;

  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  );

  Future<Result<void>> install(
    String id, {
    String? minecraftVersion,
    void Function(int, int?)? onProgress,
  });
  Future<Result<bool>> isInstalled(String id);
  Future<Result<void>> processInstallation(String id, String minecraftVersion);
  Future<Result<List<String>>> getLibrariesPath(String id);
}
