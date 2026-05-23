import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';
import 'package:yelauncher/ui/authentication/view_models/login_viewmodel.dart';
import 'package:yelauncher/ui/authentication/widgets/login_screen.dart';

GoRouter getRouter(MinecraftRepository minecraftRepository) => GoRouter(
  initialLocation: Routes.login,
  redirect: (context, state) async {
    final isAuthenticated = await minecraftRepository.isAuthenticated();

    // If user is authenticated and trying to access login, redirect to instances
    if (isAuthenticated && state.fullPath == Routes.login) {
      return Routes.instances;
    }

    // If user is not authenticated and trying to access instances, redirect to login
    if (!isAuthenticated && state.fullPath == Routes.instances) {
      return Routes.login;
    }

    return null;
  },
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
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        final viewModel = LoginViewModel(
          minecraftRepository: context.read<MinecraftRepository>(),
        );
        return LoginScreen(viewModel: viewModel);
      },
    ),
  ],
);
