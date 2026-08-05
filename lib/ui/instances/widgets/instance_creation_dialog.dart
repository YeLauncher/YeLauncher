import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:yelauncher/domain/models/minecraft/minecraft_version_model.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/checkbox.dart' as core_checkbox;
import 'package:yelauncher/ui/core/chip.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/step.dart' as core_step;
import 'package:yelauncher/ui/core/text_field.dart' as core_text_field;
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/floating_list.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_creation_viewmodel.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class InstanceCreationDialog extends StatefulWidget {
  const InstanceCreationDialog({super.key, required this.viewModel});

  final InstanceCreationViewModel viewModel;

  @override
  State<StatefulWidget> createState() => _InstanceCreationDialogState();
}

class _InstanceCreationDialogState extends State<InstanceCreationDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final OverlayPortalController _forgeMenuController = OverlayPortalController();
  final OverlayPortalController _fabricMenuController = OverlayPortalController();

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
          height: math.max(650.0, MediaQuery.sizeOf(context).height * 0.8),
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
                          AppLocalizations.of(context)!.createInstanceTitle,
                          style: AppText.defaultTheme.title.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.createInstanceSubtitle,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _stepper,
              ),
              _divider,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
          title: AppLocalizations.of(context)!.stepName,
          iconData: Symbols.edit_rounded,
          isCurrent: step == 0,
          isCompleted: step > 0,
        ),
        _spacer,
        core_step.Step.primary(
          title: AppLocalizations.of(context)!.stepAppearance,
          iconData: Symbols.palette_rounded,
          isCurrent: step == 1,
          isCompleted: step > 1,
        ),
        _spacer,
        core_step.Step.primary(
          title: AppLocalizations.of(context)!.stepVersion,
          iconData: Symbols.app_badging_rounded,
          isCurrent: step == 2,
          isCompleted: step > 2,
        ),
        _spacer,
        core_step.Step.primary(
          title: AppLocalizations.of(context)!.stepModLoader,
          iconData: Symbols.extension_rounded,
          isCurrent: step == 3,
          isCompleted: step > 3,
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (widget.viewModel.currentStep) {
      case 0:
        return _stepName;
      case 1:
        return _stepAppearance;
      case 2:
        return _stepVersion;
      case 3:
        return _stepModLoader;
      default:
        return const SizedBox.shrink();
    }
  }

  Widget get _stepName {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              AppLocalizations.of(context)!.instanceNameLabel,
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        core_text_field.TextField(
          key: const ValueKey('instance_name_input'),
          controller: _nameController,
          labelText: AppLocalizations.of(context)!.enterNameHint,
          errorText: widget.viewModel.nameError == 'nameAlreadyExists'
              ? AppLocalizations.of(context)!.nameAlreadyExists
              : widget.viewModel.nameError,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget get _stepAppearance {
    final selectedColorHex = widget.viewModel.selectedColor;
    final selectedBgColor = widget.viewModel.stylingRepository.getColor(selectedColorHex, fallback: AppColors.dark.primaryContainer);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Icon(
                    Symbols.palette_rounded,
                    size: 20,
                    weight: 600,
                    color: AppColors.dark.primary,
                  ),
                  Text(
                    AppLocalizations.of(context)!.iconLabel,
                    style: AppText.defaultTheme.label.copyWith(
                      color: AppColors.dark.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.viewModel.stylingRepository.availableIcons.map((icon) {
                  final isSelected = widget.viewModel.selectedIcon == icon;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.viewModel.selectIcon(icon),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.dark.primaryContainer : AppColors.dark.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.dark.primary : const Color(0x00000000),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            widget.viewModel.stylingRepository.getIconData(icon),
                            color: isSelected ? AppColors.dark.primary : AppColors.dark.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                spacing: 8,
                children: [
                  Icon(
                    Symbols.format_color_fill_rounded,
                    size: 20,
                    weight: 600,
                    color: AppColors.dark.primary,
                  ),
                  Text(
                    AppLocalizations.of(context)!.colorLabel,
                    style: AppText.defaultTheme.label.copyWith(
                      color: AppColors.dark.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.viewModel.stylingRepository.availableColors.map((colorHex) {
                  final isSelected = widget.viewModel.selectedColor == colorHex;
                  final color = widget.viewModel.stylingRepository.getColor(colorHex, fallback: AppColors.dark.primaryContainer);
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.viewModel.selectColor(colorHex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.dark.onSurface : const Color(0x00000000),
                            width: 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Symbols.check_rounded,
                                color: Color(0xFFFFFFFF),
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.previewLabel,
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: selectedBgColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: selectedBgColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Center(
                child: Icon(
                  widget.viewModel.stylingRepository.getIconData(widget.viewModel.selectedIcon),
                  color: const Color(0xFFFFFFFF),
                  size: 48,
                ),
              ),
            ),
          ],
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
              AppLocalizations.of(context)!.stepVersion,
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        core_text_field.TextField(
          key: const ValueKey('version_search_input'),
          controller: _searchController,
          labelText: AppLocalizations.of(context)!.searchVersionHint,
          width: double.infinity,
          isSearchField: true,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: core_checkbox.CoreCheckbox(
            value: widget.viewModel.showSnapshots,
            onChanged: (val) => widget.viewModel.toggleShowSnapshots(val ?? false),
            label: AppLocalizations.of(context)!.showSnapshots,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.viewModel.loadVersions,
            builder: (context, _) {
              if (widget.viewModel.loadVersions.running) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.loading,
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
                    AppLocalizations.of(context)!.nothingFound,
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

    return ListItem.secondary(
      key: ValueKey('version_item_${version.id}'),
      title: version.id,
      chip: typeLabel == 'Stable' ? Chip.primary(typeLabel) : Chip.secondary(typeLabel),
      // trailingIcon:
      //     "${version.releaseTime.day.toString().padLeft(2, '0')}.${version.releaseTime.month.toString().padLeft(2, '0')}.${version.releaseTime.year}",
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
                AppLocalizations.of(context)!.modLoaderLabel,
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
                    AppLocalizations.of(context)!.loading,
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
          ] else if (widget.viewModel.selectedModLoader == 'fabric') ...[
            const SizedBox(height: 24),
            _fabricVersionSelector,
          ],
        ],
      ),
    );
  }

  Widget get _forgeVersionSelector {
    final isRecommended = widget.viewModel.selectedForgeVersionSource == 'recommended';
    final isLatest = widget.viewModel.selectedForgeVersionSource == 'latest';
    final isCustom = widget.viewModel.selectedForgeVersionSource == 'custom';
    final selectedForgeVersion =
        widget.viewModel.selectedForgeVersion ?? widget.viewModel.forgeVersions.first.version;

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
              AppLocalizations.of(context)!.forgeVersionLabel,
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
                      onPressed: () {
                        widget.viewModel.selectForgeVersionSource('recommended');
                        if (_forgeMenuController.isShowing) _forgeMenuController.hide();
                        setState(() {});
                      },
                    )
                  : Button.surface(
                      "Recommended",
                      onPressed: () {
                        widget.viewModel.selectForgeVersionSource('recommended');
                        if (_forgeMenuController.isShowing) _forgeMenuController.hide();
                        setState(() {});
                      },
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLatest
                  ? Button.primary(
                      "Latest",
                      onPressed: () {
                        widget.viewModel.selectForgeVersionSource('latest');
                        if (_forgeMenuController.isShowing) _forgeMenuController.hide();
                        setState(() {});
                      },
                    )
                  : Button.surface(
                      "Latest",
                      onPressed: () {
                        widget.viewModel.selectForgeVersionSource('latest');
                        if (_forgeMenuController.isShowing) _forgeMenuController.hide();
                        setState(() {});
                      },
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isCustom
                  ? Button.primary(
                      "Custom",
                      onPressed: () {
                        widget.viewModel.selectForgeVersionSource('custom');
                        if (!_forgeMenuController.isShowing) _forgeMenuController.show();
                        setState(() {});
                      },
                    )
                  : Button.surface(
                      "Custom",
                      onPressed: () {
                        widget.viewModel.selectForgeVersionSource('custom');
                        if (!_forgeMenuController.isShowing) _forgeMenuController.show();
                        setState(() {});
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!isCustom)
          Text(
            AppLocalizations.of(context)!.selectedForgeVersion(widget.viewModel.selectedForgeVersion ?? '-'),
            style: AppText.defaultTheme.bodySmall.copyWith(
              color: AppColors.dark.onSurfaceVariant,
            ),
          ),
        if (isCustom) ...[
          Text(
            AppLocalizations.of(context)!.selectForgeVersion,
            style: AppText.defaultTheme.bodySmall.copyWith(
              color: AppColors.dark.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FloatingList(
            controller: _forgeMenuController,
            onClose: () => setState(() {}),
            overlayBuilder: (context) => _forgeMenuContent(),
            targetBuilder: (context) {
              return GestureDetector(
                onTap: () {
                  _forgeMenuController.toggle();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.dark.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.dark.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedForgeVersion,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.defaultTheme.body.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        _forgeMenuController.isShowing
                          ? Symbols.expand_less_rounded
                          : Symbols.expand_more_rounded,
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget get _fabricVersionSelector {
    final selectedFabricVersion =
        widget.viewModel.selectedFabricVersion ?? (widget.viewModel.fabricVersions.isNotEmpty ? widget.viewModel.fabricVersions.first.version : '-');

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
              AppLocalizations.of(context)!.fabricVersionLabel,
              style: AppText.defaultTheme.label.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.selectFabricVersion,
          style: AppText.defaultTheme.bodySmall.copyWith(
            color: AppColors.dark.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FloatingList(
          controller: _fabricMenuController,
          onClose: () => setState(() {}),
          overlayBuilder: (context) => _fabricMenuContent(),
          targetBuilder: (context) {
            return GestureDetector(
              onTap: () {
                _fabricMenuController.toggle();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.dark.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.dark.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedFabricVersion,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.defaultTheme.body.copyWith(
                          color: AppColors.dark.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      _fabricMenuController.isShowing
                          ? Symbols.expand_less_rounded
                          : Symbols.expand_more_rounded,
                      color: AppColors.dark.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _modLoaderButton(String id, String label, String assetPath) {
    final isSelected = widget.viewModel.selectedModLoader == id;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          key: ValueKey('mod_loader_button_$id'),
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
      ),
    );
  }

  Widget _forgeMenuContent() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.onSurface.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: widget.viewModel.forgeVersions.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: AppColors.dark.onSurface.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, index) {
          final version = widget.viewModel.forgeVersions[index];
          final isSelected = widget.viewModel.selectedForgeVersion == version.version;
          return ListItem.primary(
            title: version.version,
            subtitle: index == 0 ? 'Newest' : null,
            isSelected: isSelected,
            onTap: () {
              widget.viewModel.selectForgeVersion(version.version);
              if (_forgeMenuController.isShowing) _forgeMenuController.hide();
              setState(() {});
            },
          );
        },
      ),
      ),
    );
  }

  Widget _fabricMenuContent() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.onSurface.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: widget.viewModel.fabricVersions.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: AppColors.dark.onSurface.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, index) {
          final version = widget.viewModel.fabricVersions[index];
          final isSelected = widget.viewModel.selectedFabricVersion == version.version;
          String? badgeText;
          if (version.type == 'stable') badgeText = 'Stable';

          return ListItem.primary(
            title: version.version,
            chip: badgeText == 'Stable' ? Chip.primary(badgeText!) : null,
            isSelected: isSelected,
            onTap: () {
              widget.viewModel.selectFabricVersion(version.version);
              if (_fabricMenuController.isShowing) _fabricMenuController.hide();
              setState(() {});
            },
          );
        },
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
            AppLocalizations.of(context)!.cancel,
            onPressed: () {
              if (widget.viewModel.currentStep > 0) {
                widget.viewModel.prevStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          Button.primary(
            key: const ValueKey('instance_creation_next_button'),
            widget.viewModel.currentStep == 3 ? AppLocalizations.of(context)!.createButton : AppLocalizations.of(context)!.nextButton,
            iconData: widget.viewModel.currentStep == 3
                ? Symbols.check_rounded
                : null,
            onPressed: widget.viewModel.canProceedToNextStep
                ? () async {
                    if (widget.viewModel.currentStep == 3) {
                      await widget.viewModel.saveInstance();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      widget.viewModel.nextStep();
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
