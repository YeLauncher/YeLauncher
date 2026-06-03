import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/services/local/local_data_service.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class ForgeRepositoryLocal implements ForgeRepository {
  final LocalDataService _localDataService;

  ForgeRepositoryLocal({required LocalDataService localDataService})
    : _localDataService = localDataService;

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
      final apiModels = await _localDataService.getForgeVersions(
        minecraftVersion,
      );
      final versions = apiModels
          .map(
            (apiModel) => ModLoaderVersionModel(
              id: 'forge-${apiModel.version}',
              version: apiModel.version,
              type: 'release',
            ),
          )
          .toList();
      return Result.success(versions);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String?>> getLatestVersion(String minecraftVersion) async {
    try {
      return Result.success(
        await _localDataService.getForgeLatestVersion(minecraftVersion),
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<String?>> getRecommendedVersion(String minecraftVersion) async {
    try {
      return Result.success(
        await _localDataService.getForgeRecommendedVersion(minecraftVersion),
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  Future<Result<List<String>>> getLibrariesPath(String id) {
    return Future.value(
      Result.failure(
        Exception('Forge library lookup is not available in local mode for $id'),
      ),
    );
  }

  @override
  Future<Result<void>> install(
    String id, {
    String? minecraftVersion,
    void Function(int, int?)? onProgress,
  }) {
    return Future.value(
      Result.failure(
        Exception('Forge installation is not available in local mode for $id'),
      ),
    );
  }

  @override
  Future<Result<bool>> isInstalled(String id) {
    return Future.value(const Result.success(false));
  }

  @override
  Future<Result<void>> processInstallation(String id, String minecraftVersion) {
    return Future.value(
      Result.failure(
        Exception('Forge installation processing is not available in local mode for $id'),
      ),
    );
  }
}
