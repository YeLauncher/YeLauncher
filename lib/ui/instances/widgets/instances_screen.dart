import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_card_viewmodel.dart';
import 'package:yelauncher/ui/instances/view_models/instance_creation_viewmodel.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instance_creation_dialog.dart';
import 'package:yelauncher/ui/instances/widgets/instance_card.dart';
import 'package:yelauncher/ui/instances/widgets/instance_drawer.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class InstancesScreen extends StatefulWidget {
  const InstancesScreen({super.key, required this.viewModel});
  final InstanceScreenViewModel viewModel;
  @override
  State<StatefulWidget> createState() => _InstancesScreenState();
}

class _InstancesScreenState extends State<InstancesScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadInstances.execute();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Stack(
        children: [
          Container(
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
                      key: const ValueKey('create_instance_button'),
                      AppLocalizations.of(context)!.createButton,
                      iconData: Symbols.add_rounded,
                      onPressed: () => _showInstanceCreationDialog(context),
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
                  if (widget.viewModel.loadInstances.running && widget.viewModel.instances.isEmpty) {
                    return Center(child: CircularProgressIndicator.primary());
                  }
                  
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

                  final sortedInstances = List<InstanceModel>.from(widget.viewModel.instances)
                    ..sort((a, b) {
                      if (a.lastPlayed == null && b.lastPlayed == null) return 0;
                      if (a.lastPlayed == null) return 1;
                      if (b.lastPlayed == null) return -1;
                      return b.lastPlayed!.compareTo(a.lastPlayed!);
                    });

                  InstanceModel? lastPlayedInstance;
                  List<InstanceModel> regularInstances = sortedInstances;

                  if (sortedInstances.isNotEmpty && sortedInstances.first.lastPlayed != null) {
                    lastPlayedInstance = sortedInstances.first;
                    regularInstances = sortedInstances.sublist(1);
                  }

                  Widget buildCard(InstanceModel instance, {bool isBigCard = false}) {
                    return ChangeNotifierProvider(
                      create: (context) => InstanceCardViewModel(
                        instance: instance,
                        minecraftRepository: context.read<MinecraftRepository>(),
                        instanceRepository: context.read<InstanceRepository>(),
                        downloadService: context.read<DownloadService>(),
                        javaRepository: context.read<JavaRepository>(),
                      ),
                      child: Builder(
                        builder: (context) {
                          return InstanceCard(
                            viewModel: context.read<InstanceCardViewModel>(),
                            isBigCard: isBigCard,
                          );
                        },
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            if (lastPlayedInstance != null) ...[
                              buildCard(lastPlayedInstance, isBigCard: true),
                              const SizedBox(height: 32),
                            ],
                            if (regularInstances.isNotEmpty)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 280,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: regularInstances.length,
                                itemBuilder: (context, index) {
                                  return buildCard(regularInstances[index], isBigCard: false);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              final isDrawerOpen = widget.viewModel.selectedInstanceForDrawer != null;
              
              return Stack(
                children: [
                  if (isDrawerOpen)
                    GestureDetector(
                      onTap: widget.viewModel.closeDrawer,
                      child: Container(
                        color: AppColors.dark.scrim.withValues(alpha: 0.5),
                        constraints: const BoxConstraints.expand(),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    top: 0,
                    bottom: 0,
                    right: isDrawerOpen ? 0 : -600,
                    width: 600,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                      decoration: BoxDecoration(
                        boxShadow: [
                          if (isDrawerOpen)
                            BoxShadow(
                              color: AppColors.dark.scrim.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(-8, 0),
                            ),
                        ],
                      ),
                      child: widget.viewModel.selectedInstanceForDrawer != null
                          ? InstanceDrawer(instance: widget.viewModel.selectedInstanceForDrawer!)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
