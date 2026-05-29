import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/services/api/forge_api_client.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class ForgeRepositoryRemote implements ForgeRepository {
  final ForgeApiClient _apiClient;

  ForgeRepositoryRemote({required ForgeApiClient apiClient})
    : _apiClient = apiClient;

  @override
  String get id => 'forge';

  @override
  String get name => 'Forge';

  @override
  String get icon => 'assets/forge.svg';

  @override
  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  ) async {
    try {
      final versions = await _apiClient.getVersions(minecraftVersion);
      final mappedVersions = versions.map((apiModel) {
        return ModLoaderVersionModel(
          id: 'forge-${apiModel.version}',
          version: apiModel.version,
          type: 'release',
        );
      }).toList();
      return Result.success(mappedVersions);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String?>> getLatestVersion(String minecraftVersion) async {
    try {
      return Result.success(await _apiClient.getLatestVersion(minecraftVersion));
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String?>> getRecommendedVersion(String minecraftVersion) async {
    try {
      return Result.success(await _apiClient.getRecommendedVersion(minecraftVersion));
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }
}
