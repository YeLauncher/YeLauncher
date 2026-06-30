import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_card_viewmodel.dart';
import 'package:yelauncher/ui/instances/view_models/instance_creation_viewmodel.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instance_creation_dialog.dart';
import 'package:yelauncher/ui/instances/widgets/instance_card.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class InstancesScreen extends StatefulWidget {
  const InstancesScreen({super.key, required this.viewModel});
  final InstanceScreenViewModel viewModel;
  @override
  State<StatefulWidget> createState() => _InstancesScreenState();
}

class _InstancesScreenState extends State<InstancesScreen> {
  late final MinecraftRepository _minecraftRepository;
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadInstances.execute();
    // Cache repository reference to avoid using BuildContext across async gaps
    _minecraftRepository = context.read<MinecraftRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: BoxConstraints.expand(),
        color: AppColors.dark.surface,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 16,
                      children: [
                        Icon(
                          Symbols.sports_esports_rounded,
                          size: 40,
                          weight: 700,
                          color: AppColors.dark.primary,
                        ),
                        Text(
                          AppLocalizations.of(context)!.instancesTab,
                          style: AppText.defaultTheme.titleLarge.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.instancesSubtitle,
                      style: AppText.defaultTheme.body.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Button.primary(
                      AppLocalizations.of(context)!.createButton,
                      iconData: Symbols.add_rounded,
                      onPressed: () => _showInstanceCreationDialog(context),
                    ),
                    const SizedBox(width: 12),
                    Button.secondary(
                      AppLocalizations.of(context)!.logoutButton,
                      iconData: Symbols.logout_rounded,
                      onPressed: () async {
                        final result = await _minecraftRepository.logout();
                        if (!context.mounted) return;
                        if (result is Success<void>) {
                          context.go(Routes.login);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.instances.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          Icon(
                            Symbols.folder_off_rounded,
                            size: 80,
                            weight: 800,
                            color: AppColors.dark.onSurface,
                          ),
                          Column(
                            spacing: 4,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.noInstancesTitle,
                                style: AppText.defaultTheme.titleSmall.copyWith(
                                  color: AppColors.dark.onSurface,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.noInstancesSubtitle,
                                style: AppText.defaultTheme.bodySmall.copyWith(
                                  color: AppColors.dark.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: widget.viewModel.instances.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final instance = widget.viewModel.instances[index];
                      return ChangeNotifierProvider(
                        create: (context) => InstanceCardViewModel(
                          instance: instance,
                          minecraftRepository: context
                              .read<MinecraftRepository>(),
                          instanceRepository: context
                              .read<InstanceRepository>(),
                          downloadService: context.read<DownloadService>(),
                          javaRepository: context.read<JavaRepository>(),
                        ),
                        child: Builder(
                          builder: (context) {
                            return InstanceCard(
                              viewModel: context.read<InstanceCardViewModel>(),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstanceCreationDialog(BuildContext context) {
    final viewModel = InstanceCreationViewModel(
      minecraftRepository: context.read(),
      modLoaderRepositories: context.read(),
      instanceRepository: context.read(),
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: AppColors.dark.scrim.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (BuildContext dialogContext, animation, secondaryAnimation) {
        return Center(child: InstanceCreationDialog(viewModel: viewModel));
      },
    ).then((_) {
      viewModel.dispose();
      widget.viewModel.loadInstances.execute();
    });
  }
}
