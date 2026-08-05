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
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/pages/content_detail_page.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';

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
                return ChangeNotifierProvider(
                  create: (context) => InstanceScreenViewModel(
                    instanceRepository: context.read(),
                  ),
                  child: Consumer<InstanceScreenViewModel>(
                    builder: (context, viewModel, _) => InstancesScreen(viewModel: viewModel),
                  ),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.content,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => ContentScreenViewModel(
                    contentRepository: context.read(),
                    minecraftRepository: context.read(),
                  ),
                  child: Consumer<ContentScreenViewModel>(
                    builder: (context, viewModel, _) => ContentScreen(viewModel: viewModel),
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final extra = state.extra as Map<String, dynamic>?;
                    final item = extra?['item'] as ContentItem?;
                    final targetVersion = extra?['targetVersion'] as ContentVersion?;

                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: ChangeNotifierProvider(
                        create: (context) => ContentDetailViewModel(
                          id: id,
                          initialItem: item,
                          contentRepository: context.read(),
                          instanceRepository: context.read(),
                          breadcrumbService: context.read(),
                        )..loadDetails(),
                        child: Consumer<ContentDetailViewModel>(
                          builder: (context, viewModel, _) => ContentDetailPage(
                            viewModel: viewModel,
                            targetVersion: targetVersion,
                          ),
                        ),
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                          child: child,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profiles,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => ProfilesViewModel(
                    minecraftRepository: context.read(),
                  ),
                  child: Consumer<ProfilesViewModel>(
                    builder: (context, viewModel, _) => ProfilesScreen(viewModel: viewModel),
                  ),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (context, state) {
                return ChangeNotifierProvider(
                  create: (context) => SettingsViewModel(
                    settingsRepository: context.read(),
                    minecraftRepository: context.read(),
                  ),
                  child: Consumer<SettingsViewModel>(
                    builder: (context, viewModel, _) => SettingsScreen(viewModel: viewModel),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
