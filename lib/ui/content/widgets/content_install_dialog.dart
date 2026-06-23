import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class ContentInstallDialog extends StatefulWidget {
  final ContentDetailViewModel viewModel;
  final ContentVersion version;

  const ContentInstallDialog({
    super.key,
    required this.viewModel,
    required this.version,
  });

  @override
  State<ContentInstallDialog> createState() => _ContentInstallDialogState();
}

class _ContentInstallDialogState extends State<ContentInstallDialog> {
  InstanceModel? selectedInstance;
  bool isInstalling = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final compatibleInstances = widget.viewModel.getCompatibleInstances(widget.version);

    return Container(
      height: 400,
      width: 600,
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text('Виберіть екземпляр', style: AppText.defaultTheme.title.copyWith(color: AppColors.dark.onSurface)),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl: widget.viewModel.item.iconUrl ?? "",
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                progressIndicatorBuilder:
                    (context, url, downloadProgress) => Skeletonizer(
                  enabled: true,
                  containersColor: AppColors.dark.surfaceContainerHigh,
                  effect: ShimmerEffect(
                    baseColor: AppColors.dark.surfaceContainerHighest,
                    highlightColor: AppColors.dark.surfaceContainerHighest,
                  ),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.dark.surfaceContainerHighest,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Symbols.broken_image_rounded,
                  size: 48,
                  color: AppColors.dark.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.viewModel.item.title, style: AppText.defaultTheme.titleSmall.copyWith(color: AppColors.dark.onSurface)),
                    const SizedBox(height: 4),
                    Text(widget.viewModel.item.projectType, style: AppText.defaultTheme.bodySmall.copyWith(color: AppColors.dark.onSurfaceVariant)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text("Виберіть екземпляр, до якого потрібно додати цей мод:", style: AppText.defaultTheme.bodySmall.copyWith(color: AppColors.dark.onSurface)),
          const SizedBox(height: 12),
          if (compatibleInstances.isEmpty)
            Expanded(
              child: Center(child: Text('Немає сумісних екземплярів', style: AppText.defaultTheme.body.copyWith(color: AppColors.dark.onSurfaceVariant))),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: compatibleInstances.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final instance = compatibleInstances[index];
                  final isSelected = selectedInstance == instance;
                  return ListItem.secondary(
                    title: instance.name,
                    subtitle: '${instance.minecraftVersion} - ${instance.modLoader}',
                    trailingIcon: Symbols.check_circle_rounded,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedInstance = instance;
                      });
                    },
                  );
                },
              ),
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(errorMessage!, style: AppText.defaultTheme.bodySmall.copyWith(color: const Color(0xFFFF5555))),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button.secondary(
                'Скасувати',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Button.primary(
                isInstalling ? 'Встановлення...' : 'Встановити',
                onPressed: selectedInstance == null || isInstalling ? () {} : _install,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _install() async {
    setState(() {
      isInstalling = true;
      errorMessage = null;
    });

    try {
      final file = widget.version.files.firstWhere((f) => f.primary, orElse: () => widget.version.files.first);
      final url = file.url;
      final fileName = file.filename;
      final type = widget.viewModel.item.projectType;

      final folderName = type == 'resourcepack' ? 'resourcepacks' : 'mods';
      final relativePath = 'instances/${selectedInstance!.id}/$folderName/$fileName';

      final downloadService = context.read<DownloadService>();
      final instanceRepo = context.read<InstanceRepository>();
      await downloadService.downloadIfMissing(
        DownloadModel(url: url, path: relativePath, sha1: ''),
      );

      // Add to instance installed content
      final content = InstalledContentModel(
        projectId: widget.viewModel.item.id,
        versionId: widget.version.id,
        filename: fileName,
        title: widget.viewModel.item.title,
        type: type,
      );

      final newInstalledContent = List<InstalledContentModel>.from(selectedInstance!.installedContent)..add(content);
      final updatedInstance = selectedInstance!.copyWith(installedContent: newInstalledContent);

      await instanceRepo.saveInstance(updatedInstance);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Помилка: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isInstalling = false;
        });
      }
    }
  }
}
