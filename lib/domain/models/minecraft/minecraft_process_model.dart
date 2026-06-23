class MinecraftProcessModel {
  final Future<int> exitCode;
  final Stream<List<int>> stdout;
  final Stream<List<int>> stderr;
  final bool Function() kill;

  const MinecraftProcessModel({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.kill,
  });
}
