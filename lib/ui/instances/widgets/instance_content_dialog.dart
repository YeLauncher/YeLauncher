import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class InstanceContentDialog extends StatefulWidget {
  final InstanceModel instance;

  const InstanceContentDialog({super.key, required this.instance});

  @override
  State<InstanceContentDialog> createState() => _InstanceContentDialogState();
}

class _InstanceContentDialogState extends State<InstanceContentDialog> {
  late InstanceModel _instance;

  @override
  void initState() {
    super.initState();
    _instance = widget.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Встановлений контент',
                style: AppText.defaultTheme.titleLarge.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Symbols.close,
                  color: AppColors.dark.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_instance.installedContent.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Контент відсутній',
                  style: AppText.defaultTheme.body.copyWith(
                    color: AppColors.dark.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _instance.installedContent.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _instance.installedContent[index];
                  return ListItem.primary(
                    title: item.title,
                    subtitle: '${item.type} - ${item.filename}',
                    isSelected: false,
                    onTap: () => _removeContent(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _removeContent(InstalledContentModel item) async {
    final instanceRepo = context.read<InstanceRepository>();
    final folderName = item.type == 'resourcepack' ? 'resourcepacks' : 'mods';
    final appData = await getApplicationSupportDirectory();
    final file = File(
      p.join(
        appData.path,
        'instances',
        _instance.id,
        folderName,
        item.filename,
      ),
    );

    if (await file.exists()) {
      await file.delete();
    }

    final newContent = _instance.installedContent
        .where(
          (i) => i.projectId != item.projectId || i.versionId != item.versionId,
        )
        .toList();
    final updatedInstance = _instance.copyWith(installedContent: newContent);

    if (!mounted) return;
    await instanceRepo.saveInstance(updatedInstance);

    setState(() {
      _instance = updatedInstance;
    });
  }
}
