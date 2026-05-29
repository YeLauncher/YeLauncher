import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/step.dart' as core_step;
import 'package:yelauncher/ui/core/text_field.dart' as core_text_field;
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_creation_viewmodel.dart';

class InstanceCreationDialog extends StatefulWidget {
  const InstanceCreationDialog({super.key, required this.viewModel});

  final InstanceCreationViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _InstanceCreationDialogState();
}

class _InstanceCreationDialogState extends State<InstanceCreationDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      widget.viewModel.updateName(_nameController.text);
    });
    _searchController.addListener(() {
      widget.viewModel.updateSearchQuery(_searchController.text);
    });
    widget.viewModel.loadVersions.execute();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Container(
          width: 700,
          height: math.max(550.0, MediaQuery.sizeOf(context).height * 0.75),
          decoration: BoxDecoration(
            color: AppColors.dark.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 28,
                ),
                child: Row(
                  spacing: 16,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      Symbols.add_circle_rounded,
                      size: 32,
                      weight: 600,
                      color: AppColors.dark.primary,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 4,
                      children: [
                        Text(
                          "Створити екземпляр",
                          style: AppText.defaultTheme.title.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                        ),
                        Text(
                          "Налаштуйте свій екземпляр",
                          style: AppText.defaultTheme.bodySmall.copyWith(
                            color: AppColors.dark.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _divider,
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _stepper,
              ),
              _divider,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  child: _buildCurrentStep(),
                ),
              ),
              _divider,
              _footer,
            ],
          ),
        );
      },
    );
  }

  Widget get _divider => Container(
    height: 1,
    color: AppColors.dark.onSurface.withValues(alpha: 0.08),
  );

  Widget get _spacer => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 2,
      width: 40,
      color: AppColors.dark.onSurface.withValues(alpha: 0.08),
    ),
  );

  Widget get _stepper {
    final step = widget.viewModel.currentStep;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        core_step.Step.primary(
          title: "Назва",
          iconData: Symbols.edit_rounded,
          isCurrent: step == 0,
          isCompleted: step > 0,
        ),
        _spacer,
        core_step.Step.primary(
          title: "Версія",
          iconData: Symbols.app_badging_rounded,
          isCurrent: step == 1,
          isCompleted: step > 1,
        ),
        _spacer,
        core_step.Step.primary(
          title: "Завантажувач",
          iconData: Symbols.extension_rounded,
          isCurrent: step == 2,
          isCompleted: step > 2,
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (widget.viewModel.currentStep) {
      case 0:
        return _stepName;
      case 1:
        return _stepVersion;
      case 2:
        return _stepModLoader;
      // You can add steps 3 here later
      default:
        return const SizedBox.shrink();
    }
  }

  Widget get _stepName {
    return Column(
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(
              Symbols.label_rounded,
              size: 20,
              weight: 600,
              color: AppColors.dark.primary,
            ),
            Text(
              "Назва екземпляру",
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        core_text_field.TextField(
          controller: _nameController,
          labelText: "Введіть назву",
          width: double.infinity,
        ),
      ],
    );
  }

  Widget get _stepVersion {
    return Column(
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(
              Symbols.arrow_circle_down_rounded,
              size: 20,
              weight: 600,
              color: AppColors.dark.primary,
            ),
            Text(
              "Версія",
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        core_text_field.TextField(
          controller: _searchController,
          labelText: "Пошук версії",
          width: double.infinity,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.viewModel.loadVersions,
            builder: (context, _) {
              if (widget.viewModel.loadVersions.running) {
                return Center(
                  child: Text(
                    "Завантаження...",
                    style: AppText.defaultTheme.body.copyWith(
                      color: AppColors.dark.primary,
                    ),
                  ),
                );
              }

              final versions = widget.viewModel.filteredVersions;

              if (versions.isEmpty && widget.viewModel.searchQuery.isNotEmpty) {
                return Center(
                  child: Text(
                    "Нічого не знайдено",
                    style: AppText.defaultTheme.body.copyWith(
                      color: AppColors.dark.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: versions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final version = versions[index];
                  return _versionItem(version);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _versionItem(MinecraftVersionModel version) {
    String typeLabel = version.type;
    if (typeLabel == 'release') typeLabel = 'Stable';
    if (typeLabel == 'snapshot') typeLabel = 'Snapshot';
    if (typeLabel == 'old_alpha') typeLabel = 'Alpha';
    if (typeLabel == 'old_beta') typeLabel = 'Beta';

    final isSelected = widget.viewModel.selectedVersion?.id == version.id;

    return ListItem(
      title: version.id,
      badgeText: typeLabel,
      badgeColor: typeLabel == 'Stable'
          ? AppColors.dark.onPrimaryContainer
          : AppColors.transparent,
      badgeBackgroundColor: typeLabel == 'Stable'
          ? AppColors.dark.primaryContainer
          : AppColors.transparent,
      trailingText:
          "${version.releaseTime.day.toString().padLeft(2, '0')}.${version.releaseTime.month.toString().padLeft(2, '0')}.${version.releaseTime.year}",
      isSelected: isSelected,
      onTap: () => widget.viewModel.selectVersion(version),
    );
  }

  Widget get _stepModLoader {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(
                Symbols.extension_rounded,
                size: 20,
                weight: 600,
                color: AppColors.dark.primary,
              ),
              Text(
                "Завантажувач модів",
                style: AppText.defaultTheme.label.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: widget.viewModel.loadModLoaders,
            builder: (context, _) {
              if (widget.viewModel.loadModLoaders.running) {
                return Center(
                  child: Text(
                    "Завантаження...",
                    style: AppText.defaultTheme.body.copyWith(
                      color: AppColors.dark.primary,
                    ),
                  ),
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 24,
                children: [
                  _modLoaderButton('vanilla', 'Vanilla', Assets.minecraftLogo),
                  for (final loader in widget.viewModel.availableModLoaders)
                    _modLoaderButton(loader.id, loader.name, loader.icon),
                ],
              );
            },
          ),
          if (widget.viewModel.selectedModLoader == 'forge') ...[
            const SizedBox(height: 24),
            _forgeVersionSelector,
          ],
        ],
      ),
    );
  }

  Widget get _forgeVersionSelector {
    final isRecommended = widget.viewModel.selectedForgeVersionSource == 'recommended';
    final isLatest = widget.viewModel.selectedForgeVersionSource == 'latest';
    final isCustom = widget.viewModel.selectedForgeVersionSource == 'custom';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(
              Symbols.app_badging_rounded,
              size: 20,
              weight: 600,
              color: AppColors.dark.primary,
            ),
            Text(
              "Forge версія",
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: isRecommended
                  ? Button.primary(
                      "Recommended",
                      onPressed: () => widget.viewModel.selectForgeVersionSource('recommended'),
                    )
                  : Button.surface(
                      "Recommended",
                      onPressed: () => widget.viewModel.selectForgeVersionSource('recommended'),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLatest
                  ? Button.primary(
                      "Latest",
                      onPressed: () => widget.viewModel.selectForgeVersionSource('latest'),
                    )
                  : Button.surface(
                      "Latest",
                      onPressed: () => widget.viewModel.selectForgeVersionSource('latest'),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isCustom
                  ? Button.primary(
                      "Custom",
                      onPressed: () => widget.viewModel.selectForgeVersionSource('custom'),
                    )
                  : Button.surface(
                      "Custom",
                      onPressed: () => widget.viewModel.selectForgeVersionSource('custom'),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!isCustom)
          Text(
            "Selected Forge version: ${widget.viewModel.selectedForgeVersion ?? '-'}",
            style: AppText.defaultTheme.bodySmall.copyWith(
              color: AppColors.dark.onSurfaceVariant,
            ),
          ),
        if (isCustom) ...[
          Text(
            "Виберіть одну з доступних версій Forge",
            style: AppText.defaultTheme.bodySmall.copyWith(
              color: AppColors.dark.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.viewModel.forgeVersions.isEmpty)
            Text(
              "Немає доступних версій Forge для цієї версії Minecraft",
              style: AppText.defaultTheme.bodySmall.copyWith(
                color: AppColors.dark.onSurfaceVariant,
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                itemCount: widget.viewModel.forgeVersions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final version = widget.viewModel.forgeVersions[index];
                  final isSelected = widget.viewModel.selectedForgeVersion == version.version;
                  return ListItem(
                    title: version.version,
                    badgeText: index == 0 ? 'Newest' : null,
                    isSelected: isSelected,
                    onTap: () => widget.viewModel.selectForgeVersion(version.version),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _modLoaderButton(String id, String label, String assetPath) {
    final isSelected = widget.viewModel.selectedModLoader == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.viewModel.selectModLoader(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.dark.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 2,
              color: isSelected
                  ? AppColors.dark.primary
                  : AppColors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              SvgPicture.asset(assetPath, height: 64),
              Text(
                label,
                style: AppText.defaultTheme.labelLarge.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _footer {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Button.surface(
            "Скасувати",
            onPressed: () {
              if (widget.viewModel.currentStep > 0) {
                widget.viewModel.prevStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          Button.primary(
            widget.viewModel.currentStep == 2 ? "Створити" : "Далі",
            iconData: widget.viewModel.currentStep == 2
                ? Symbols.check_rounded
                : null,
            onPressed: () async {
              if (widget.viewModel.currentStep == 2) {
                await widget.viewModel.saveInstance();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                widget.viewModel.nextStep();
              }
            },
          ),
        ],
      ),
    );
  }
}
