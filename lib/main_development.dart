import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/config/dependencies.dart';

import 'main.dart';

void main() {
  Logger.root.level = Level.ALL; // Set the logging level to capture all logs

  runApp(
    MultiProvider(providers: providersLocal, child: const YeLauncherApp()),
  );
}
