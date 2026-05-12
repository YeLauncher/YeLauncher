class MinecraftRunModel {
  final List<String> libraryPaths;
  final List<String> nativeLibraryPaths;
  final List<String> jvmArguments;
  final List<String> gameArguments;
  final String mainClass;
  final String assetsDirectory;
  final String gameDirectory;
  final String nativesDirectory;
  final String clientJarPath;
  final String javaExecutablePath;

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
  });
}
