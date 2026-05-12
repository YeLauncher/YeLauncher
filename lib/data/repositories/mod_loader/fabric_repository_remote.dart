import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/api/fabric_api_client.dart';
import 'package:yelauncher/domain/models/mod_loader/mod_loader_version_model.dart';
import 'package:yelauncher/utilities/result.dart';

class FabricRepositoryRemote implements ModLoaderRepository {
  final FabricApiClient _apiClient;

  FabricRepositoryRemote({required FabricApiClient apiClient})
    : _apiClient = apiClient;

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
      final versions = await _apiClient.getVersions(minecraftVersion);
      final mappedVersions = versions.map((apiModel) {
        return ModLoaderVersionModel(
          id: 'fabric-${apiModel.version}',
          version: apiModel.version,
          type: apiModel.stable ? 'stable' : 'snapshot',
        );
      }).toList();
      return Result.success(mappedVersions);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }
}
