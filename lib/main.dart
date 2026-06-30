import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yelauncher/config/dependencies.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/routing/router.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

void main() async {
  Logger.root.level = Level.FINE; // Set the logging level to capture all logs
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions options = WindowOptions(
    size: Size(1200, 750),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: AppColors.dark.surface,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(
    MultiProvider(providers: providersRemote, child: const YeLauncherApp()),
  );
}

class YeLauncherApp extends StatefulWidget {
  const YeLauncherApp({super.key});

  @override
  State<YeLauncherApp> createState() => _YeLauncherAppState();
}

class _YeLauncherAppState extends State<YeLauncherApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize the router once to prevent resetting to initialLocation on rebuilds
    final minecraftRepository = context.read<MinecraftRepository>();
    _router = getRouter(minecraftRepository);
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      title: "YeLauncher",
      color: AppColors.dark.surface,
      routerConfig: _router,
    );
  }
}
