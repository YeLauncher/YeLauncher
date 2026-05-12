import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

abstract class ModLoaderRepository {
  String get id;
  String get name;
  String get icon;

  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  );
}
