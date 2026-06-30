import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_screen.dart';
import 'package:yelauncher/ui/core/main_layout.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';
import 'package:yelauncher/ui/authentication/view_models/login_viewmodel.dart';
import 'package:yelauncher/ui/authentication/widgets/login_screen.dart';

import 'package:yelauncher/ui/splash/view_models/splash_viewmodel.dart';
import 'package:yelauncher/ui/splash/widgets/splash_screen.dart';
import 'package:yelauncher/ui/settings/view_models/settings_viewmodel.dart';
import 'package:yelauncher/ui/settings/widgets/settings_screen.dart';

GoRouter getRouter(MinecraftRepository minecraftRepository) => GoRouter(
  initialLocation: Routes.splash,
  redirect: (context, state) async {
    if (state.fullPath == Routes.splash) {
      return null;
    }

    final isAuthenticated = await minecraftRepository.isAuthenticated();

    // If user is authenticated and trying to access login, redirect to instances
    if (isAuthenticated && state.fullPath == Routes.login) {
      return Routes.instances;
    }

    // If user is not authenticated and trying to access instances or content, redirect to login
    if (!isAuthenticated && state.fullPath != Routes.login) {
      return Routes.login;
    }

    return null;
  },
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
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        final viewModel = LoginViewModel(
          minecraftRepository: context.read<MinecraftRepository>(),
        );
        return LoginScreen(viewModel: viewModel);
      },
    ),
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
                );
                return ContentScreen(viewModel: viewModel);
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
