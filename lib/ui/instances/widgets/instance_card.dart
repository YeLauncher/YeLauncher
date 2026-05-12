import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_card_viewmodel.dart';

class InstanceCard extends StatefulWidget {
  final InstanceCardViewModel viewModel;

  const InstanceCard({super.key, required this.viewModel});

  @override
  State<InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<InstanceCard> {
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
              if (widget.viewModel.isDownloading || widget.viewModel.installInstance.running) ...[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      value: widget.viewModel.downloadProgress,
                      color: AppColors.dark.primary,
                      backgroundColor: AppColors.dark.surfaceContainerHigh,
                    ),
                  ),
                ),
              ] else if (widget.viewModel.instance.isInstalled == false) ...[
                Button.primary(
                  "Встановити",
                  iconData: Symbols.download_rounded,
                  onPressed: widget.viewModel.installInstance.execute,
                ),
              ] else if (widget.viewModel.instance.isInstalled == true) ...[
                Button.primary(
                  "Грати",
                  iconData: Symbols.play_arrow_rounded,
                  onPressed: widget.viewModel.runInstance.execute,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
