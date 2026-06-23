import 'package:yelauncher/domain/models/minecraft/minecraft_profile_model.dart';

class MinecraftRunModel {
  final List<String> libraryPaths;
  final List<String> nativeLibraryPaths;
  final List<String> jvmArguments;
  final List<String> gameArguments;
  final String minecraftVersion;
  final String mainClass;
  final String assetIndex;
  final String assetsDirectory;
  final String gameDirectory;
  final String libraryDirectory;
  final String nativesDirectory;
  final String clientJarPath;
  final String javaExecutablePath;
  final MinecraftProfileModel profile;

  MinecraftRunModel({
    required this.libraryPaths,
    required this.nativeLibraryPaths,
    required this.jvmArguments,
    required this.gameArguments,
    required this.mainClass,
    required this.assetsDirectory,
    required this.gameDirectory,
    required this.nativesDirectory,
    required this.clientJarPath,
    required this.javaExecutablePath,
    required this.libraryDirectory,
    required this.assetIndex,
    required this.minecraftVersion,
    required this.profile,
  });
}
