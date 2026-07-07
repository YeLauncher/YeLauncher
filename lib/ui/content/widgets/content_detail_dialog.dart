import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_install_dialog.dart';
import 'package:yelauncher/ui/core/chip.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/icon_button.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

class ContentDetailDialog extends StatefulWidget {
  final ContentDetailViewModel viewModel;

  const ContentDetailDialog({super.key, required this.viewModel});

  @override
  State<ContentDetailDialog> createState() => _ContentDetailDialogState();
}

class _ContentDetailDialogState extends State<ContentDetailDialog> {
  int _selectedTabIndex = 0;

  List<String> _getTabLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.tabDescription, l10n.tabGallery, l10n.tabVersions];
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadDetails();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<ContentDetailViewModel>(
        builder: (context, vm, child) {
          return Container(
            width: 800,
            height: 600,
            decoration: BoxDecoration(
              color: AppColors.dark.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (vm.item.iconUrl != null)
                      Image.network(
                        vm.item.iconUrl!,
                        width: 64,
                        height: 64,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.item.title,
                            style: AppText.defaultTheme.titleLarge.copyWith(
                              color: AppColors.dark.onSurface,
                            ),
                          ),
                          _buildChips(vm),
                        ],
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
            Row(
              spacing: 8,
              children: List.generate(_getTabLabels(context).length, (index) {
                final isSelected = index == _selectedTabIndex;
                return GestureDetector(
                  onTap: () => _onTabSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.dark.primaryContainer
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getTabLabels(context)[index],
                      style: AppText.defaultTheme.label.copyWith(
                        color: isSelected
                            ? AppColors.dark.onPrimaryContainer
                            : AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (vm.isLoading) {
                    return Center(child: CircularProgressIndicator.primary());
                  }

                  if (_selectedTabIndex == 0) {
                    return _buildDescriptionTab(vm);
                  } else if (_selectedTabIndex == 1) {
                    return _buildGalleryTab(vm);
                  } else {
                    return _buildVersionsTab(vm);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }),
  );
}

  String _formatGameVersions(List<String> versions) {
    if (versions.isEmpty) return '';
    if (versions.length == 1) return versions.first;
    return '${versions.first}-${versions.last}';
  }

  Widget _buildDescriptionTab(ContentDetailViewModel vm) {
    final item = vm.fullItem ?? vm.item;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: AppText.defaultTheme.body.copyWith(
              color: AppColors.dark.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(ContentDetailViewModel vm) {
    final item = vm.fullItem ?? vm.item;
    final authorName = item.author ?? vm.item.author ?? item.organization ?? item.teamId;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (authorName != null)
          Chip.surface(authorName, iconData: Symbols.person_rounded),
        if (item.downloads != null)
          Chip.surface(
            NumberFormat.compact().format(item.downloads!),
            iconData: Symbols.download_rounded,
          ),
        if (item.gameVersions != null)
          Chip.surface(
            _formatGameVersions(item.gameVersions!),
            iconData: Symbols.gamepad_rounded,
          ),
        if (item.loaders != null)
          for (final loader in item.loaders!) Chip.surface(loader),
      ],
    );
  }

  Widget _buildGalleryTab(ContentDetailViewModel vm) {
    final item = vm.fullItem;
    if (item == null || item.gallery == null || item.gallery!.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.galleryEmpty,
          style: TextStyle(color: AppColors.dark.onSurface),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: item.gallery!.length,
      itemBuilder: (context, index) {
        final image = item.gallery![index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(image.url, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildVersionsTab(ContentDetailViewModel vm) {
    if (vm.versions.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.versionsNotFound,
          style: TextStyle(color: AppColors.dark.onSurface),
        ),
      );
    }
    return ListView.separated(
      itemCount: vm.versions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final version = vm.versions[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.dark.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.name,
                      style: AppText.defaultTheme.title.copyWith(
                        color: AppColors.dark.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ...version.gameVersions.map(
                          (gv) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dark.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              gv,
                              style: AppText.defaultTheme.label.copyWith(
                                color: AppColors.dark.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        ...version.loaders.map(
                          (loader) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dark.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              loader,
                              style: AppText.defaultTheme.label.copyWith(
                                color: AppColors.dark.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton.transparent(
                onPressed: () {
                  _showInstallDialog(context, version);
                },
                iconData: Symbols.download_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInstallDialog(BuildContext context, ContentVersion version) {
    if (widget.viewModel.item.projectType == 'modpack') {
      // Modpacks installing not implemented yet
      return;
    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        pageBuilder: (context, anim1, anim2) => Center(
          child: ContentInstallDialog(
            viewModel: widget.viewModel,
            version: version,
          ),
        ),
      );
    }
  }
}
