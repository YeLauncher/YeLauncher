import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/utilities/result.dart';

abstract class ForgeRepository implements ModLoaderRepository {
  Future<Result<String?>> getLatestVersion(String minecraftVersion);

  Future<Result<String?>> getRecommendedVersion(String minecraftVersion);
}

