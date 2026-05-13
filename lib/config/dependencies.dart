import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository_local.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/repositories/java/java_repository_remote.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository_remote.dart';
import 'package:yelauncher/data/repositories/mod_loader/fabric_repository_local.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository_local.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/local/local_data_service.dart';
import 'package:yelauncher/data/services/api/fabric_api_client.dart';
import 'package:yelauncher/data/services/api/forge_api_client.dart';
import 'package:yelauncher/data/repositories/mod_loader/fabric_repository_remote.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository_remote.dart';

import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/instance_service.dart';
import 'package:yelauncher/data/services/local/file_service.dart';
import 'package:yelauncher/data/services/local/minecraft_service.dart';

List<SingleChildWidget> get providersLocal {
  return [
    Provider.value(value: LocalDataService()),
    Provider(create: (_) => FileService()),
    Provider(create: (_) => MinecraftService()),
    Provider<JavaRepository>(create: (_) => JavaRepositoryRemote()),
    ChangeNotifierProvider(create: (context) => DownloadService()),
    Provider.value(
      value: MinecraftApiClient(
        baseUrl:
            'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json',
      ),
    ),
    Provider<MinecraftRepository>(
      create: (context) => MinecraftRepositoryRemote(
        apiClient: context.read(),
        minecraftService: context.read(),
        downloadService: context.read(),
        fileService: context.read(),
        javaRepository: context.read(),
      ),
    ),
    Provider<InstanceService>(create: (context) => InstanceService()),
    Provider<InstanceRepository>(
      create: (context) =>
          InstanceRepositoryLocal(
                instanceService: context.read<InstanceService>(),
                minecraftService: context.read<MinecraftService>(),
              )
              as InstanceRepository,
    ),
    Provider(
      create: (context) =>
          FabricRepositoryLocal(localDataService: context.read()),
    ),
    Provider(
      create: (context) =>
          ForgeRepositoryLocal(localDataService: context.read()),
    ),
    Provider<List<ModLoaderRepository>>(
      create: (context) => [
        context.read<FabricRepositoryLocal>(),
        context.read<ForgeRepositoryLocal>(),
      ],
    ),
  ];
}

List<SingleChildWidget> get providersRemote {
  return [
    Provider.value(
      value: MinecraftApiClient(
        baseUrl:
            'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json',
      ),
    ),
    Provider(create: (_) => FileService()),
    Provider(create: (_) => MinecraftService()),
    Provider<JavaRepository>(create: (_) => JavaRepositoryRemote()),
    ChangeNotifierProvider(create: (context) => DownloadService()),
    Provider<InstanceService>(create: (context) => InstanceService()),
    Provider<InstanceRepository>(
      create: (context) =>
          InstanceRepositoryLocal(
                instanceService: context.read<InstanceService>(),
                minecraftService: context.read<MinecraftService>(),
              )
              as InstanceRepository,
    ),
    Provider<MinecraftRepository>(
      create: (context) => MinecraftRepositoryRemote(
        apiClient: context.read(),
        minecraftService: context.read(),
        downloadService: context.read(),
        fileService: context.read(),
        javaRepository: context.read(),
      ),
    ),
    Provider.value(value: FabricApiClient()),
    Provider.value(value: ForgeApiClient()),
    Provider<FabricRepositoryRemote>(
      create: (context) => FabricRepositoryRemote(apiClient: context.read()),
    ),
    Provider<ForgeRepositoryRemote>(
      create: (context) => ForgeRepositoryRemote(apiClient: context.read()),
    ),
    Provider<List<ModLoaderRepository>>(
      create: (context) => [
        context.read<FabricRepositoryRemote>(),
        context.read<ForgeRepositoryRemote>(),
      ],
    ),
  ];
}
