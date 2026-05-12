import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/local/local_data_service.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class ForgeRepositoryLocal implements ModLoaderRepository {
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
}
