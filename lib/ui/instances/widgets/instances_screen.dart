import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart'
    show showDialog, AlertDialog, showGeneralDialog;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_styling_repository.dart';
import 'package:yelauncher/data/repositories/minecraft/minecraft_repository.dart';
import 'package:yelauncher/data/repositories/mod_loader/mod_loader_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/data/repositories/java/java_repository.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/dropdown.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/text_field.dart' as ye_text_field;
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.viewModel.searchQuery;
    _searchController.addListener(() {
      widget.viewModel.searchQuery = _searchController.text;
    });
    widget.viewModel.loadInstances.execute();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          spacing: 8,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            widget.viewModel.isSelectionMode
                                ? Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.selectedCount(
                                          widget.viewModel.selectedInstanceIds.length,
                                        ),
                                        style: AppText.defaultTheme.titleMedium.copyWith(
                                          color: AppColors.dark.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Button.surface(
                                        AppLocalizations.of(context)!.selectAllButton,
                                        iconData: Symbols.select_all_rounded,
                                        onPressed: widget.viewModel.selectAll,
                                      ),
                                      const SizedBox(width: 8),
                                      Button.surface(
                                        AppLocalizations.of(context)!.cancel,
                                        iconData: Symbols.close_rounded,
                                        onPressed: widget.viewModel.toggleSelectionMode,
                                      ),
                                      const SizedBox(width: 8),
                                      Button.error(
                                        AppLocalizations.of(context)!.deleteButton,
                                        iconData: Symbols.delete_rounded,
                                        onPressed: widget.viewModel.selectedInstanceIds.isEmpty
                                            ? null
                                            : () => _showDeleteConfirmationDialog(context),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Button.surface(
                                        AppLocalizations.of(context)!.selectButton,
                                        iconData: Symbols.checklist_rounded,
                                        onPressed: widget.viewModel.toggleSelectionMode,
                                      ),
                                      const SizedBox(width: 16),
                                      Selector<InstanceScreenViewModel, InstanceSortOrder>(
                                        selector: (_, viewModel) => viewModel.sortOrder,
                                        builder: (context, sortOrder, _) {
                                          return Dropdown<InstanceSortOrder>(
                                            iconData: Symbols.sort_rounded,
                                            value: sortOrder,
                                            items: [
                                              DropdownItem(
                                                value: InstanceSortOrder.lastPlayed,
                                                label: AppLocalizations.of(context)!.sortLastPlayed,
                                              ),
                                              DropdownItem(
                                                value: InstanceSortOrder.nameAsc,
                                                label: AppLocalizations.of(context)!.sortNameAsc,
                                              ),
                                              DropdownItem(
                                                value: InstanceSortOrder.nameDesc,
                                                label: AppLocalizations.of(context)!.sortNameDesc,
                                              ),
                                            ],
                                            onChanged: (val) => widget.viewModel.sortOrder = val,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 250,
                              child: ye_text_field.TextField(
                                controller: _searchController,
                                labelText: AppLocalizations.of(context)!.searchInstances,
                                isSearchField: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Button.primary(
                              key: const ValueKey('create_instance_button'),
                              AppLocalizations.of(context)!.createButton,
                              iconData: Symbols.add_rounded,
                              onPressed: () => _showInstanceCreationDialog(context),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      if (widget.viewModel.loadInstances.running &&
                          widget.viewModel.instances.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator.primary(),
                        );
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
                                    AppLocalizations.of(
                                      context,
                                    )!.noInstancesTitle,
                                    style: AppText.defaultTheme.headlineSmall
                                        .copyWith(
                                          color: AppColors.dark.onSurface,
                                        ),
                                  ),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noInstancesSubtitle,
                                    style: AppText.defaultTheme.bodyLarge
                                        .copyWith(
                                          color:
                                              AppColors.dark.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      final sortedInstances =
                          widget.viewModel.filteredAndSortedInstances;

                      InstanceModel? lastPlayedInstance;
                      List<InstanceModel> regularInstances = sortedInstances;

                      if (sortedInstances.isNotEmpty &&
                          sortedInstances.first.lastPlayed != null) {
                        lastPlayedInstance = sortedInstances.first;
                        regularInstances = sortedInstances.sublist(1);
                      }

                      Widget buildCard(
                        InstanceModel instance, {
                        bool isBigCard = false,
                      }) {
                        final isSelectionMode =
                            widget.viewModel.isSelectionMode;
                        final isSelected = widget.viewModel.selectedInstanceIds
                            .contains(instance.id);

                        return ChangeNotifierProvider(
                          key: ValueKey(instance.id),
                          create: (context) => InstanceCardViewModel(
                            instance: instance,
                            minecraftRepository: context
                                .read<MinecraftRepository>(),
                            instanceRepository: context
                                .read<InstanceRepository>(),
                            downloadService: context.read<DownloadService>(),
                            javaRepository: context.read<JavaRepository>(),
                            stylingRepository: context.read<InstanceStylingRepository>(),
                          ),
                          child: Builder(
                            builder: (context) {
                              return InstanceCard(
                                viewModel: context
                                    .read<InstanceCardViewModel>(),
                                isBigCard: isBigCard,
                                isSelectionMode: isSelectionMode,
                                isSelected: isSelected,
                                onSelect: () => widget.viewModel
                                    .toggleInstanceSelection(instance.id),
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
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 280,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1.0,
                                    ),
                                itemCount: regularInstances.length,
                                itemBuilder: (context, index) {
                                  return buildCard(
                                    regularInstances[index],
                                    isBigCard: false,
                                  );
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
              final isDrawerOpen =
                  widget.viewModel.selectedInstanceForDrawer != null;

              final drawerWidth = (MediaQuery.sizeOf(context).width * 0.7).clamp(600.0, 900.0);

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
                    right: isDrawerOpen ? 0 : -drawerWidth,
                    width: drawerWidth,
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        right: 8,
                      ),
                      decoration: BoxDecoration(
                        boxShadow: [
                          if (isDrawerOpen)
                            BoxShadow(
                              color: AppColors.dark.scrim.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 24,
                              offset: const Offset(-8, 0),
                            ),
                        ],
                      ),
                      child: widget.viewModel.selectedInstanceForDrawer != null
                          ? InstanceDrawer(
                              instance:
                                  widget.viewModel.selectedInstanceForDrawer!,
                            )
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
      minecraftRepository: context.read<MinecraftRepository>(),
      modLoaderRepositories: context.read<List<ModLoaderRepository>>(),
      instanceRepository: context.read<InstanceRepository>(),
      stylingRepository: context.read<InstanceStylingRepository>(),
      existingInstanceNames: widget.viewModel.instances
          .map((i) => i.name)
          .toList(),
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.dark.surfaceContainerHigh,
          title: Text(
            AppLocalizations.of(context)!.deleteInstanceTitle,
            style: AppText.defaultTheme.headlineSmall.copyWith(
              color: AppColors.dark.onSurface,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.deleteInstanceContent,
            style: AppText.defaultTheme.bodyLarge.copyWith(
              color: AppColors.dark.onSurfaceVariant,
            ),
          ),
          actions: [
            Button.surface(
              AppLocalizations.of(context)!.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            Button.error(
              AppLocalizations.of(context)!.deleteButton,
              onPressed: () async {
                Navigator.of(context).pop();
                await widget.viewModel.deleteSelectedInstances();
              },
            ),
          ],
        );
      },
    );
  }
}
