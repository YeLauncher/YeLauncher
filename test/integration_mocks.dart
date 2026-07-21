import 'package:mockito/annotations.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';

@GenerateNiceMocks([
  MockSpec<MinecraftRepository>(),
  MockSpec<ContentRepository>(),
  MockSpec<ModLoaderRepository>(),
  MockSpec<DownloadService>(),
])
void main() {}
