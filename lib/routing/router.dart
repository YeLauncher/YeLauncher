import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_screen.dart';
import 'package:yelauncher/ui/core/main_layout.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';
import 'package:yelauncher/ui/settings/view_models/settings_viewmodel.dart';
import 'package:yelauncher/ui/settings/widgets/settings_screen.dart';
import 'package:yelauncher/ui/profiles/view_models/profiles_viewmodel.dart';
import 'package:yelauncher/ui/profiles/widgets/profiles_screen.dart';
import 'package:yelauncher/ui/splash/view_models/splash_viewmodel.dart';
import 'package:yelauncher/ui/splash/widgets/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter getRouter(MinecraftRepository minecraftRepository) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.splash,
  observers: [HeroController()],
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) {
        final viewModel = SplashViewModel(
          instanceRepository: context.read(),
          updateService: context.read(),
        );
        return SplashScreen(viewModel: viewModel);
      },
    ),
    // Login route removed
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.instances,
              builder: (context, state) {
                final viewModel = InstanceScreenViewModel(
                  instanceRepository: context.read(),
                );
                return InstancesScreen(viewModel: viewModel);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.content,
              builder: (context, state) {
                final viewModel = ContentScreenViewModel(
                  contentRepository: context.read(),
                  minecraftRepository: context.read(),
                );
                return ContentScreen(viewModel: viewModel);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profiles,
              builder: (context, state) {
                final viewModel = ProfilesViewModel(
                  minecraftRepository: context.read(),
                );
                return ProfilesScreen(viewModel: viewModel);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) {
                final viewModel = SettingsViewModel(
                  settingsRepository: context.read(),
                  minecraftRepository: context.read(),
                );
                return SettingsScreen(viewModel: viewModel);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
