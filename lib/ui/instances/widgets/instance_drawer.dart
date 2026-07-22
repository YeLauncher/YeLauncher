import 'dart:io';

import 'package:flutter/material.dart' show AlertDialog, showDialog;
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/chip.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/icon_button.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/switch_button.dart';
import 'package:yelauncher/ui/core/text_field.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';

class _DisplayContent {
  final String filename;
  final String type;
  final bool isManaged;
  final InstalledContentModel? model;
  final bool fileExists;
  final bool isDisabled;

  _DisplayContent({
    required this.filename,
    required this.type,
    required this.isManaged,
    this.model,
    required this.fileExists,
    required this.isDisabled,
  });
}

class InstanceDrawer extends StatefulWidget {
  final InstanceModel instance;

  const InstanceDrawer({super.key, required this.instance});

  @override
  State<InstanceDrawer> createState() => _InstanceDrawerState();
}

class _InstanceDrawerState extends State<InstanceDrawer> {
  int _currentTabIndex = 0; // 0: Settings, 1: Content

  // Content Tab State
  List<_DisplayContent> _allContentItems = [];
  List<_DisplayContent> _displayItems = [];
  bool _isLoadingContent = true;
  String _searchQuery = '';
  bool _sortAscending = true;
  late TextEditingController _searchController;

  // Settings Tab State
  late TextEditingController _nameController;
  late TextEditingController _memoryController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _javaPathController;
  late TextEditingController _jvmArgsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFilters();
      });
    });
    _initSettingsState();
    _loadContent();
  }

  bool _contentChanged(List<InstalledContentModel> old, List<InstalledContentModel> current) {
    if (old.length != current.length) return true;
    for (int i = 0; i < old.length; i++) {
      if (old[i].filename != current[i].filename) return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(InstanceDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance.id != widget.instance.id ||
        _contentChanged(oldWidget.instance.installedContent, widget.instance.installedContent)) {
      _initSettingsState();
      _loadContent();
    }
  }

  void _initSettingsState() {
    _nameController = TextEditingController(text: widget.instance.name);
    _memoryController = TextEditingController(
      text: widget.instance.javaMemory?.toString() ?? '',
    );
    _widthController = TextEditingController(
      text: widget.instance.windowWidth?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.instance.windowHeight?.toString() ?? '',
    );
    _javaPathController = TextEditingController(
      text: widget.instance.customJavaPath ?? '',
    );
    _jvmArgsController = TextEditingController(
      text: widget.instance.jvmArguments ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoryController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _javaPathController.dispose();
    _jvmArgsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final repo = context.read<InstanceRepository>();
      final updatedInstance = InstanceModel(
        id: widget.instance.id,
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : widget.instance.name,
        minecraftVersion: widget.instance.minecraftVersion,
        modLoader: widget.instance.modLoader,
        modLoaderVersion: widget.instance.modLoaderVersion,
        isInstalled: widget.instance.isInstalled,
        installedContent: widget.instance.installedContent,
        lastPlayed: widget.instance.lastPlayed,
        javaMemory: int.tryParse(_memoryController.text),
        windowWidth: int.tryParse(_widthController.text),
        windowHeight: int.tryParse(_heightController.text),
        customJavaPath: _javaPathController.text.trim().isEmpty
            ? null
            : _javaPathController.text.trim(),
        jvmArguments: _jvmArgsController.text.trim().isEmpty
            ? null
            : _jvmArgsController.text.trim(),
      );

      await repo.saveInstance(updatedInstance);
      if (mounted) {
        context.read<InstanceScreenViewModel>().loadInstances.execute();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoadingContent = true);

    final appData = await getApplicationSupportDirectory();
    final instanceDir = Directory(
      p.join(appData.path, 'instances', widget.instance.id),
    );
    final modsDir = Directory(p.join(instanceDir.path, 'mods'));
    final rpDir = Directory(p.join(instanceDir.path, 'resourcepacks'));

    final List<_DisplayContent> items = [];
    final Map<String, InstalledContentModel> managedMap = {
      for (var content in widget.instance.installedContent)
        Uri.decodeFull(content.filename): content,
    };

    Future<void> scanDir(Directory dir, String defaultType) async {
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>();
        for (var file in files) {
          final filename = p.basename(file.path);
          final isDisabled = filename.endsWith('.disabled');

          if (filename.endsWith('.jar') ||
              filename.endsWith('.zip') ||
              isDisabled) {
            final decodedFilename = Uri.decodeFull(filename);
            final model = managedMap[decodedFilename] ??
                managedMap['$decodedFilename.disabled'] ??
                managedMap[decodedFilename.replaceAll('.disabled', '')];

            items.add(
              _DisplayContent(
                filename: filename,
                type: model?.type ?? defaultType,
                isManaged: model != null,
                model: model,
                fileExists: true,
                isDisabled: isDisabled,
              ),
            );
            if (model != null) {
              managedMap.remove(Uri.decodeFull(model.filename));
            }
          }
        }
      }
    }

    await scanDir(modsDir, 'mod');
    await scanDir(rpDir, 'resourcepack');

    for (var model in managedMap.values) {
      items.add(
        _DisplayContent(
          filename: model.filename,
          type: model.type,
          isManaged: true,
          model: model,
          fileExists: false,
          isDisabled: model.filename.endsWith('.disabled'),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _allContentItems = items;
        _isLoadingContent = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    var filtered = _allContentItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.filename.toLowerCase().contains(q) ||
          (item.model?.title.toLowerCase().contains(q) ?? false);
    }).toList();

    filtered.sort((a, b) {
      if (a.isManaged != b.isManaged) return a.isManaged ? -1 : 1;
      final cmp = a.filename.compareTo(b.filename);
      return _sortAscending ? cmp : -cmp;
    });

    setState(() {
      _displayItems = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumb Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () =>
                        context.read<InstanceScreenViewModel>().closeDrawer(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dark.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.dark.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.arrow_back_rounded,
                            color: AppColors.dark.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.instancesTab,
                            style: AppText.defaultTheme.titleSmall.copyWith(
                              color: AppColors.dark.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Symbols.chevron_right_rounded,
                    color: AppColors.dark.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.instance.name,
                    style: AppText.defaultTheme.titleSmall.copyWith(
                      color: AppColors.dark.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 32, right: 32, bottom: 32),
              decoration: BoxDecoration(
                color: AppColors.dark.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: _buildTabs(),
                  ),
                  Container(height: 1, color: AppColors.dark.outlineVariant),
                  Expanded(
                    child: _currentTabIndex == 0
                        ? _buildSettingsTab()
                        : _buildContentTab(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            AppLocalizations.of(context)!.settingsTabTitle,
            0,
            Symbols.settings_rounded,
          ),
          _buildTabItem(
            AppLocalizations.of(context)!.installedContentTitle,
            1,
            Symbols.inventory_2_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, IconData icon) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.dark.primary
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.dark.onPrimary
                    : AppColors.dark.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.defaultTheme.labelLarge.copyWith(
                    color: isSelected ? AppColors.dark.onPrimary : AppColors.dark.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 32,
              children: [
                _buildFormSection(
                  title: AppLocalizations.of(context)!.settingsGeneralTitle,
                  iconData: Symbols.tune_rounded,
                  children: [
                    _buildSettingsRow(
                      title: AppLocalizations.of(context)!.instanceNameLabel,
                      description: AppLocalizations.of(
                        context,
                      )!.settingsInstanceNameDesc,
                      child: TextField(
                        controller: _nameController,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ),
                _buildFormSection(
                  title: AppLocalizations.of(context)!.settingsMinecraftTitle,
                  iconData: Symbols.desktop_windows_rounded,
                  children: [
                    _buildSettingsRow(
                      title: AppLocalizations.of(
                        context,
                      )!.settingsWindowResolution,
                      description: AppLocalizations.of(
                        context,
                      )!.settingsWindowResolutionDesc,
                      child: Row(
                        spacing: 16,
                        children: [
                          Expanded(
                            child: TextField(
                              labelText: AppLocalizations.of(
                                context,
                              )!.settingsWidth,
                              controller: _widthController,
                              width: double.infinity,
                            ),
                          ),
                          Text(
                            'x',
                            style: AppText.defaultTheme.titleSmall.copyWith(
                              color: AppColors.dark.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              labelText: AppLocalizations.of(
                                context,
                              )!.settingsHeight,
                              controller: _heightController,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildFormSection(
                  title: AppLocalizations.of(context)!.settingsJavaEnvironment,
                  iconData: Symbols.memory_rounded,
                  children: [
                    _buildSettingsRow(
                      title: AppLocalizations.of(context)!.settingsMaxMemory,
                      description: AppLocalizations.of(
                        context,
                      )!.settingsMaxMemoryDesc,
                      child: TextField(
                        labelText: AppLocalizations.of(context)!.settingsMB,
                        controller: _memoryController,
                        width: double.infinity,
                      ),
                    ),
                    _buildSettingsRow(
                      title: AppLocalizations.of(
                        context,
                      )!.settingsCustomJavaPath,
                      description: AppLocalizations.of(
                        context,
                      )!.settingsCustomJavaPathDesc,
                      child: TextField(
                        controller: _javaPathController,
                        width: double.infinity,
                      ),
                    ),
                    _buildSettingsRow(
                      title: AppLocalizations.of(context)!.settingsJvmArgs,
                      description: AppLocalizations.of(
                        context,
                      )!.settingsJvmArgsDesc,
                      child: TextField(
                        controller: _jvmArgsController,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: AppColors.dark.outlineVariant),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Button.error(
                AppLocalizations.of(context)!.deleteButton,
                onPressed: _deleteInstance,
                iconData: Symbols.delete_rounded,
              ),
              if (_isSaving)
                CircularProgressIndicator.primary(size: 24)
              else
                Button.primary(
                  AppLocalizations.of(context)!.saveChangesButton,
                  onPressed: _saveSettings,
                  iconData: Symbols.save_rounded,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteInstance() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dark.surfaceContainerHigh,
        title: Text(
          AppLocalizations.of(context)!.deleteInstanceTitle,
          style: AppText.defaultTheme.titleSmall.copyWith(
            color: AppColors.dark.onSurface,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteInstanceContent,
          style: AppText.defaultTheme.body.copyWith(
            color: AppColors.dark.onSurfaceVariant,
          ),
        ),
        actions: [
          Button.surface(
            AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          Button.error(
            AppLocalizations.of(context)!.deleteButton,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        final instanceRepo = context.read<InstanceRepository>();
        await instanceRepo.deleteInstance(widget.instance.id);
        if (mounted) {
          context.read<InstanceScreenViewModel>().loadInstances.execute();
          context.read<InstanceScreenViewModel>().closeDrawer();
        }
      }
    }
  }

  Widget _buildSettingsRow({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.defaultTheme.labelLarge.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppText.defaultTheme.bodySmall.copyWith(
                  color: AppColors.dark.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(flex: 3, child: child),
      ],
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData iconData,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Icon(iconData, color: AppColors.dark.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppText.defaultTheme.titleSmall.copyWith(
                    color: AppColors.dark.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    if (_isLoadingContent) {
      return Center(child: CircularProgressIndicator.primary());
    }

    if (_allContentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(
              Symbols.folder_off_rounded,
              size: 64,
              color: AppColors.dark.onSurfaceVariant,
            ),
            Text(
              AppLocalizations.of(context)!.contentMissing,
              style: AppText.defaultTheme.titleSmall.copyWith(
                color: AppColors.dark.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  labelText: 'Search...',
                ),
              ),
              const SizedBox(width: 16),
              Button.surface(
                _sortAscending ? 'A-Z' : 'Z-A',
                iconData: _sortAscending
                    ? Symbols.sort_by_alpha_rounded
                    : Symbols.sort_rounded,
                onPressed: () {
                  _sortAscending = !_sortAscending;
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.dark.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: _displayItems.isEmpty 
                  ? Center(
                      child: Text(
                        'No results found',
                        style: AppText.defaultTheme.titleSmall.copyWith(
                          color: AppColors.dark.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _displayItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _displayItems[index];
                        return ListItem.primary(
                          title:
                              item.model?.title ??
                              item.filename.replaceAll('.disabled', ''),
                          subtitle: item.isManaged 
                              ? '${item.type} - v${item.model?.version} by ${item.model?.author}'
                              : '${item.type} - ${item.filename}${!item.fileExists ? AppLocalizations.of(context)!.missingFile : ''}',
                          isSelected: false,
                          chip: item.isManaged
                              ? Chip.primary(
                                  AppLocalizations.of(context)!.launcherManaged,
                                  iconData: Symbols.rocket_launch_rounded)
                              : Chip.surface(
                                  AppLocalizations.of(context)!.manualInstalled,
                                  iconData: Symbols.folder_rounded),
                          trailingWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SwitchButton(
                                value: !item.isDisabled,
                                onChanged: (value) => _toggleContent(item),
                              ),
                              const SizedBox(width: 16),
                              IconButton.transparent(
                                onPressed: () => _removeContent(item),
                                iconData: Symbols.delete_rounded,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeContent(_DisplayContent item) async {
    final instanceRepo = context.read<InstanceRepository>();
    final folderName = item.type == 'resourcepack' ? 'resourcepacks' : 'mods';
    final appData = await getApplicationSupportDirectory();
    final file = File(
      p.join(
        appData.path,
        'instances',
        widget.instance.id,
        folderName,
        Uri.decodeFull(item.filename),
      ),
    );

    if (await file.exists()) {
      await file.delete();
    }

    if (item.isManaged) {
      final newContent = widget.instance.installedContent
          .where((c) => c.projectId != item.model!.projectId || c.versionId != item.model!.versionId)
          .toList();
      final updatedInstance = widget.instance.copyWith(
        installedContent: newContent,
      );
      await instanceRepo.saveInstance(updatedInstance);

      if (mounted) {
        context.read<InstanceScreenViewModel>().loadInstances.execute();
      }
    }

    _loadContent(); // Reload local list
  }

  Future<void> _toggleContent(_DisplayContent item) async {
    final instanceRepo = context.read<InstanceRepository>();
    final folderName = item.type == 'resourcepack' ? 'resourcepacks' : 'mods';
    final appData = await getApplicationSupportDirectory();
    final file = File(
      p.join(
        appData.path,
        'instances',
        widget.instance.id,
        folderName,
        Uri.decodeFull(item.filename),
      ),
    );

    if (await file.exists()) {
      final newFilename = item.isDisabled
          ? item.filename.replaceAll('.disabled', '')
          : '${item.filename}.disabled';

      final newFile = File(
        p.join(
          appData.path,
          'instances',
          widget.instance.id,
          folderName,
          Uri.decodeFull(newFilename),
        ),
      );
      await file.rename(newFile.path);

      if (item.isManaged && item.model != null) {
        final newContent = widget.instance.installedContent.map((c) {
          if (c.projectId == item.model!.projectId && c.versionId == item.model!.versionId) {
            return c.copyWith(filename: newFilename);
          }
          return c;
        }).toList();

        final updatedInstance = widget.instance.copyWith(
          installedContent: newContent,
        );
        await instanceRepo.saveInstance(updatedInstance);

        if (mounted) {
          context.read<InstanceScreenViewModel>().loadInstances.execute();
        }
      }

      _loadContent();
    }
  }
}
