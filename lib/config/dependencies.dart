import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository_local.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/data/repositories/java/java_repository_remote.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository_remote.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/fabric_repository_local.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository_local.dart';
import 'package:yelauncher/data/services/api/minecraft_api_client.dart';
import 'package:yelauncher/data/services/local/local_data_service.dart';
import 'package:yelauncher/data/services/api/fabric_api_client.dart';
import 'package:yelauncher/data/services/api/forge_api_client.dart';
import 'package:yelauncher/data/repositories/mod_loader/fabric_repository_remote.dart';
import 'package:yelauncher/data/repositories/mod_loader/forge_repository_remote.dart';
import 'package:yelauncher/data/services/secure_storage_service.dart';

import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/services/instance_service.dart';
import 'package:yelauncher/data/services/file_service.dart';
import 'package:yelauncher/data/services/minecraft_service.dart';


List<SingleChildWidget> get _sharedProviders {
  return [
    Provider(create: (_) => FileService()),
    Provider(create: (_) => MinecraftService()),
    Provider(create: (_) => const FlutterSecureStorage()),
    Provider(create: (_) => SecureStorageService()),
    Provider.value(
      value: MinecraftApiClient(
        baseUrl:
        'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json',
      ),
    ),
  ];
}

List<SingleChildWidget> get providersLocal {
  return [
    ..._sharedProviders,
    Provider.value(value: LocalDataService()),
    Provider<JavaRepository>(create: (_) => JavaRepositoryRemote()),
    Provider(create: (context) => DownloadService()),
    Provider<InstanceService>(
      create: (context) => InstanceService(
        apiClient: context.read(),
        javaRepository: context.read(),
      ),
    ),
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
    Provider<ForgeRepository>(
      create: (context) => context.read<ForgeRepositoryLocal>(),
    ),
    Provider<MinecraftRepository>(
      create: (context) => MinecraftRepositoryRemote(
        apiClient: context.read(),
        minecraftService: context.read(),
        downloadService: context.read(),
        fileService: context.read(),
        javaRepository: context.read(),
        secureStorage: context.read(),
        forgeRepository: context.read(),
      ),
    ),
    Provider<List<ModLoaderRepository>>(
      create: (context) => [
        context.read<FabricRepositoryLocal>(),
        context.read<ForgeRepository>(),
      ],
    ),
  ];
}

List<SingleChildWidget> get providersRemote {
  return [
    ..._sharedProviders,
    Provider<JavaRepository>(create: (_) => JavaRepositoryRemote()),
    Provider(create: (context) => DownloadService()),
    Provider<InstanceService>(
      create: (context) => InstanceService(
        apiClient: context.read(),
        javaRepository: context.read(),
      ),
    ),
    Provider<InstanceRepository>(
      create: (context) =>
          InstanceRepositoryLocal(
                instanceService: context.read<InstanceService>(),
                minecraftService: context.read<MinecraftService>(),
              )
              as InstanceRepository,
    ),
    Provider.value(value: FabricApiClient()),
    Provider.value(value: ForgeApiClient()),
    Provider<FabricRepositoryRemote>(
      create: (context) => FabricRepositoryRemote(apiClient: context.read()),
    ),
    Provider<ForgeRepository>(
      create: (context) => ForgeRepositoryRemote(
        apiClient: context.read(),
        downloadService: context.read(),
        fileService: context.read(),
      ),
    ),
    Provider<MinecraftRepository>(
      create: (context) => MinecraftRepositoryRemote(
        apiClient: context.read(),
        minecraftService: context.read(),
        downloadService: context.read(),
        fileService: context.read(),
        javaRepository: context.read(),
        secureStorage: context.read(),
        forgeRepository: context.read(),
      ),
    ),
    Provider<List<ModLoaderRepository>>(
      create: (context) => [
        context.read<FabricRepositoryRemote>(),
        context.read<ForgeRepository>(),
      ],
    ),
  ];
}
