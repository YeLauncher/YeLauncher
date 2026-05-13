import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yelauncher/config/dependencies.dart';
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

class YeLauncherApp extends StatelessWidget {
  const YeLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      title: "YeLauncher",
      color: AppColors.dark.surface,
      routerConfig: router,
      builder: (context, child) {
        return child!;
      },
    );
  }
}
