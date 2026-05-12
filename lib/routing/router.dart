import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instances_screen.dart';

GoRouter get router => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final viewModel = InstanceScreenViewModel(
          instanceRepository: context.read(),
        );
        return InstancesScreen(viewModel: viewModel);
      },
    ),
  ],
);
