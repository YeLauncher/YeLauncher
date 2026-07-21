import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Tooltip, showDialog, AlertDialog;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/icon_button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_card_viewmodel.dart';
import 'package:yelauncher/ui/instances/widgets/instance_content_dialog.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/utilities/result.dart' as yelauncher_result;
import 'package:go_router/go_router.dart' as go_router;
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';

class InstanceCard extends StatefulWidget {
  final InstanceCardViewModel viewModel;

  const InstanceCard({super.key, required this.viewModel});

  @override
  State<InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<InstanceCard> {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 16,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.dark.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Symbols.inventory_2_rounded,
                      color: AppColors.dark.primary,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Text(
                        widget.viewModel.instance.name,
                        style: AppText.defaultTheme.titleSmall.copyWith(
                          color: AppColors.dark.onSurface,
                        ),
                      ),
                      Text(
                        "${widget.viewModel.instance.minecraftVersion} • ${widget.viewModel.instance.modLoader} ${widget.viewModel.instance.modLoaderVersion}",
                        style: AppText.defaultTheme.bodySmall.copyWith(
                          color: AppColors.dark.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (widget.viewModel.isDownloading || widget.viewModel.installInstance.running)
                    Tooltip(
                      message: widget.viewModel.currentInstallStep ?? AppLocalizations.of(context)!.installingTooltip,
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
                  else if (widget.viewModel.instance.isInstalled == false)
                    Button.primary(
                      AppLocalizations.of(context)!.installButton,
                      iconData: Symbols.download_rounded,
                      onPressed: () async {
                        await widget.viewModel.installInstance.execute();
                        _handleCommandResult(widget.viewModel.installInstance.result);
                        if (widget.viewModel.installInstance.result is yelauncher_result.Success && mounted) {
                          context.read<InstanceScreenViewModel>().loadInstances.execute();
                        }
                      },
                    )
                  else if (widget.viewModel.instance.isInstalled == true) ...[
                    if (widget.viewModel.isRunning)
                      Button.error(
                        AppLocalizations.of(context)!.stopButton,
                        iconData: Symbols.stop_rounded,
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
                      Button.primary(
                        AppLocalizations.of(context)!.playButton,
                        iconData: Symbols.play_arrow_rounded,
                        onPressed: () async {
                          await widget.viewModel.runInstance.execute();
                          _handleCommandResult(widget.viewModel.runInstance.result);
                        },
                      ),
                    IconButton.surface(
                      iconData: Symbols.folder_open_rounded,
                      onPressed: widget.viewModel.openFolder.execute,
                    ),
                    IconButton.surface(
                      iconData: Symbols.extension_rounded,
                      onPressed: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "Dismiss",
                          pageBuilder: (context, anim1, anim2) => Center(
                            child: InstanceContentDialog(instance: widget.viewModel.instance),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
