class LauncherException implements Exception {

  final String message;
  @override
  String toString() {
    return message;
  }

  const LauncherException(this.message);

}
