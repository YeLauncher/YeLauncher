import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/local/local_data_service.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class FabricRepositoryLocal implements ModLoaderRepository {
  final LocalDataService _localDataService;

  FabricRepositoryLocal({required LocalDataService localDataService})
    : _localDataService = localDataService;

  @override
  String get id => 'fabric';

  @override
  String get name => 'Fabric';

  @override
  String get icon => 'assets/fabric.svg';

  @override
  Future<Result<List<ModLoaderVersionModel>>> getVersions(
    String minecraftVersion,
  ) async {
    try {
      final apiModels = await _localDataService.getFabricVersions(
        minecraftVersion,
      );
      final versions = apiModels
          .map(
            (apiModel) => ModLoaderVersionModel(
              id: 'fabric-${apiModel.version}',
              version: apiModel.version,
              type: apiModel.stable ? 'stable' : 'snapshot',
            ),
          )
          .toList();
      return Result.success(versions);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }
}
