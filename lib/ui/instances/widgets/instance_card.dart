import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart'
    show showDialog, AlertDialog, SystemMouseCursors;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/chip.dart' as ye_chip;
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/icon_button.dart' as ye_icon_button;
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/core/tooltip.dart';
import 'package:yelauncher/ui/instances/view_models/instance_card_viewmodel.dart';

import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/utilities/result.dart' as yelauncher_result;
import 'package:go_router/go_router.dart' as go_router;
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';

class InstanceCard extends StatefulWidget {
  final InstanceCardViewModel viewModel;
  final bool isBigCard;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const InstanceCard({
    super.key,
    required this.viewModel,
    this.isBigCard = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<InstanceCard> {
  bool _isHovered = false;

  void _handleCommandResult(dynamic result) {
    if (result is yelauncher_result.Failure) {
      final errorStr = result.error.toString();
      if (errorStr.contains('authenticated')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.dark.surfaceContainerHigh,
            title: Text(
              AppLocalizations.of(context)!.authenticationRequiredTitle,
              style: AppText.defaultTheme.titleSmall.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.authenticationRequiredDescription,
              style: AppText.defaultTheme.body.copyWith(
                color: AppColors.dark.onSurfaceVariant,
              ),
            ),
            actions: [
              Button.primary(
                AppLocalizations.of(context)!.goToProfilesButton,
                onPressed: () {
                  Navigator.of(context).pop();
                  go_router.GoRouter.of(context).go('/profiles');
                },
              ),
              Button.surface(
                AppLocalizations.of(context)!.closeButton,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.dark.surfaceContainerHigh,
            title: Text(
              'Error',
              style: AppText.defaultTheme.titleSmall.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.errorWithParam(errorStr),
              style: AppText.defaultTheme.body.copyWith(
                color: AppColors.dark.onSurfaceVariant,
              ),
            ),
            actions: [
              Button.surface(
                AppLocalizations.of(context)!.closeButton,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  String _getLocalizedStep(BuildContext context) {
    final step = widget.viewModel.rawInstallStep;
    if (step == null) return AppLocalizations.of(context)!.installingStatus;

    if (step.startsWith('Downloading Java ')) {
      final version = step.substring(17);
      return AppLocalizations.of(context)!.installStepDownloadingJava(version);
    }
    if (step == 'Installation client & assets') {
      return AppLocalizations.of(context)!.installStepInstallingClientAndAssets;
    }
    if (step == 'Processing Forge installation...') {
      return AppLocalizations.of(context)!.installStepProcessingForge;
    }
    if (step == 'Processing Fabric installation...') {
      return AppLocalizations.of(context)!.installStepProcessingFabric;
    }
    return step;
  }

  Widget _buildIcon({required double size, required double iconSize}) {
    final instanceColor = widget.viewModel.instance.color;
    final instanceIcon = widget.viewModel.instance.icon;

    final bgColor = widget.viewModel.stylingRepository.getColor(instanceColor, fallback: AppColors.dark.primaryContainer);

    final iconColor = instanceColor != null
        ? const Color(0xFFFFFFFF)
        : AppColors.dark.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(widget.viewModel.stylingRepository.getIconData(instanceIcon), color: iconColor, size: iconSize),
    );
  }

  Widget _buildModLoaderChip() {
    final modLoader = widget.viewModel.instance.modLoader.toLowerCase();
    String? svgIcon;
    IconData? iconData;

    switch (modLoader) {
      case 'fabric':
        svgIcon = 'assets/fabric.svg';
        break;
      case 'forge':
        svgIcon = 'assets/forge.svg';
        break;
      case 'vanilla':
        svgIcon = 'assets/minecraft.svg';
        break;
      default:
        iconData = Symbols.settings_applications_rounded;
    }

    return ye_chip.Chip.surface(
      widget.viewModel.instance.modLoader,
      iconData: iconData,
      svgIcon: svgIcon,
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    return [
      if (widget.viewModel.isDownloading ||
          widget.viewModel.installInstance.running)
        Tooltip(
          message: () {
            final stepText = _getLocalizedStep(context);
            final total = widget.viewModel.totalInstallBytes;
            final completed = widget.viewModel.completedInstallBytes;
            if (total != null && completed != null) {
              final completedMB = (completed / (1024 * 1024)).toStringAsFixed(
                2,
              );
              final totalMB = (total / (1024 * 1024)).toStringAsFixed(2);
              return '$stepText ($completedMB MB / $totalMB MB)';
            }
            return stepText;
          }(),
          preferBelow: false,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator.primary(
                value:
                    widget.viewModel.javaDownloadProgress ??
                    widget.viewModel.downloadProgress,
              ),
            ),
          ),
        )
      else if (widget.viewModel.instance.isInstalled == false) ...[
        Button.primary(
          key: ValueKey(
            'instance_install_button_${widget.viewModel.instance.id}',
          ),
          AppLocalizations.of(context)!.installButton,
          iconData: Symbols.download_rounded,
          onPressed: () async {
            await widget.viewModel.installInstance.execute();
            if (!context.mounted) return;
            _handleCommandResult(widget.viewModel.installInstance.result);
            if (widget.viewModel.installInstance.result
                is yelauncher_result.Success) {
              context.read<InstanceScreenViewModel>().loadInstances.execute();
            }
          },
        ),
        ye_icon_button.IconButton.surface(
          iconData: Symbols.settings_rounded,
          onPressed: () {
            context.read<InstanceScreenViewModel>().openDrawer(
              widget.viewModel.instance,
            );
          },
        ),
      ] else if (widget.viewModel.instance.isInstalled == true) ...[
        if (widget.viewModel.isRunning)
          ye_icon_button.IconButton(
            iconData: Symbols.stop_rounded,
            backgroundColor: AppColors.dark.secondary,
            iconColor: AppColors.dark.onSecondary,
            onPressed: widget.viewModel.stopInstance.execute,
          )
        else if (widget.viewModel.runInstance.running)
          SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator.primary(),
            ),
          )
        else
          ye_icon_button.IconButton(
            key: ValueKey(
              'instance_play_button_${widget.viewModel.instance.id}',
            ),
            iconData: Symbols.play_arrow_rounded,
            backgroundColor: AppColors.dark.primary,
            iconColor: AppColors.dark.onPrimary,
            onPressed: () async {
              await widget.viewModel.runInstance.execute();
              if (!context.mounted) return;
              _handleCommandResult(widget.viewModel.runInstance.result);
            },
          ),
        ye_icon_button.IconButton.surface(
          iconData: Symbols.snippet_folder_rounded,
          onPressed: widget.viewModel.openFolder.execute,
        ),
        ye_icon_button.IconButton.surface(
          iconData: Symbols.settings_rounded,
          onPressed: () {
            context.read<InstanceScreenViewModel>().openDrawer(
              widget.viewModel.instance,
            );
          },
        ),
      ],
    ];
  }

  Widget _buildBigCard(BuildContext context) {
    final bool showButtons =
        !widget.isSelectionMode &&
        (_isHovered ||
            widget.viewModel.isRunning ||
            widget.viewModel.isDownloading ||
            widget.viewModel.installInstance.running ||
            widget.viewModel.runInstance.running);

    return AnimatedScale(
      scale: _isHovered ? 1.01 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.dark.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.dark.primary
                : _isHovered
                ? AppColors.dark.primary.withValues(alpha: 0.3)
                : const Color(0x00000000),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(size: 80, iconSize: 40),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModLoaderChip(),
                  const SizedBox(height: 8),
                  Text(
                    widget.viewModel.instance.name,
                    style: AppText.defaultTheme.titleLarge.copyWith(
                      color: AppColors.dark.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.viewModel.instance.minecraftVersion} • ${widget.viewModel.instance.modLoaderVersion}",
                    style: AppText.defaultTheme.body.copyWith(
                      color: AppColors.dark.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isSelectionMode)
              Icon(
                widget.isSelected
                    ? Symbols.check_circle_rounded
                    : Symbols.radio_button_unchecked_rounded,
                color: widget.isSelected
                    ? AppColors.dark.primary
                    : AppColors.dark.onSurfaceVariant,
                size: 32,
                fill: widget.isSelected ? 1.0 : 0.0,
              )
            else
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: showButtons ? 1.0 : 0.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: _buildButtons(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final bool showButtons =
        !widget.isSelectionMode &&
        (_isHovered ||
            widget.viewModel.isRunning ||
            widget.viewModel.isDownloading ||
            widget.viewModel.installInstance.running ||
            widget.viewModel.runInstance.running);

    return AnimatedScale(
      scale: _isHovered ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dark.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.dark.primary
                : _isHovered
                ? AppColors.dark.primary.withValues(alpha: 0.3)
                : const Color(0x00000000),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModLoaderChip(),
                    const Spacer(),
                    Center(child: _buildIcon(size: 72, iconSize: 36)),
                    const Spacer(),
                    Text(
                      widget.viewModel.instance.name,
                      style: AppText.defaultTheme.titleSmall.copyWith(
                        color: AppColors.dark.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.viewModel.instance.minecraftVersion,
                      style: AppText.defaultTheme.bodySmall.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelectionMode)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(
                    widget.isSelected
                        ? Symbols.check_circle_rounded
                        : Symbols.radio_button_unchecked_rounded,
                    color: widget.isSelected
                        ? AppColors.dark.primary
                        : AppColors.dark.onSurfaceVariant,
                    size: 28,
                    fill: widget.isSelected ? 1.0 : 0.0,
                  ),
                ),
              if (showButtons)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showButtons ? 1.0 : 0.0,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: AppColors.dark.surfaceContainerHigh.withValues(
                          alpha: 0.6,
                        ),
                        child: Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: _buildButtons(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isSelectionMode ? widget.onSelect : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, child) {
            if (widget.isBigCard) {
              return _buildBigCard(context);
            } else {
              return _buildGridCard(context);
            }
          },
        ),
      ),
    );
  }
}
