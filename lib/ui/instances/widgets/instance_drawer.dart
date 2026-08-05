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
import 'package:yelauncher/data/repositories/settings/settings_repository.dart';
import 'package:yelauncher/data/services/system_info_service.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/chip.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/checkbox.dart';
import 'package:yelauncher/ui/core/icon_button.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/slider.dart';
import 'package:yelauncher/ui/core/switch_button.dart';
import 'package:yelauncher/ui/core/text_field.dart';
import 'package:yelauncher/ui/core/tooltip.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/instances/view_models/instance_screen_viewmodel.dart';
import 'package:yelauncher/ui/core/tabs.dart';

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
  final Set<String> _selectedMods = {};
  bool _isSelectionMode = false;

  // Settings Tab State
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _isSaving = false;

  // Memory slider state (null means 'inherit global')
  double? _memorySliderValue;
  bool _useInstanceMemory = false;
  int _maxMemoryMB = 16384;

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
    _fetchSystemMemory();
  }

  bool _contentChanged(
    List<InstalledContentModel> old,
    List<InstalledContentModel> current,
  ) {
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
        _contentChanged(
          oldWidget.instance.installedContent,
          widget.instance.installedContent,
        )) {
      _initSettingsState();
      _loadContent();
    }
  }

  void _initSettingsState() {
    _nameController = TextEditingController(text: widget.instance.name);
    _useInstanceMemory = widget.instance.javaMemory != null;
    _memorySliderValue = widget.instance.javaMemory?.toDouble();
    _widthController = TextEditingController(
      text: widget.instance.windowWidth?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.instance.windowHeight?.toString() ?? '',
    );
  }

  Future<void> _fetchSystemMemory() async {
    final systemInfo = SystemInfoService();
    final totalMB = await systemInfo.getTotalPhysicalMemoryMB();
    if (mounted) {
      setState(() {
        _maxMemoryMB = totalMB;
        if (_memorySliderValue != null && _memorySliderValue! > _maxMemoryMB) {
          _memorySliderValue = _maxMemoryMB.toDouble();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
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
        javaMemory: _useInstanceMemory ? _memorySliderValue?.toInt() : null,
        windowWidth: int.tryParse(_widthController.text),
        windowHeight: int.tryParse(_heightController.text),
        customJavaPath: widget.instance.customJavaPath,
        jvmArguments: widget.instance.jvmArguments,
      );

      await repo.saveInstance(updatedInstance);
      if (mounted) {
        context.read<InstanceScreenViewModel>().loadInstances.execute();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefaults() async {
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
        javaMemory: null,
        windowWidth: null,
        windowHeight: null,
        customJavaPath: null,
        jvmArguments: null,
      );

      await repo.saveInstance(updatedInstance);
      if (mounted) {
        _useInstanceMemory = false;
        _memorySliderValue = null;
        _widthController.clear();
        _heightController.clear();
        context.read<InstanceScreenViewModel>().loadInstances.execute();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadContent({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoadingContent = true);
      _selectedMods.clear();
    }

    final appData = await getApplicationSupportDirectory();
    final instanceDir = Directory(
      p.join(appData.path, 'instances', widget.instance.id),
    );
    final modsDir = Directory(p.join(instanceDir.path, 'mods'));
    final rpDir = Directory(p.join(instanceDir.path, 'resourcepacks'));
    final spDir = Directory(p.join(instanceDir.path, 'shaderpacks'));

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
            final model =
                managedMap[decodedFilename] ??
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
    await scanDir(spDir, 'shader');

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
                Tooltip(
                  message: AppLocalizations.of(context)!.instancesTab,
                  child: IconButton.surface(
                    onPressed: () =>
                        context.read<InstanceScreenViewModel>().closeDrawer(),
                    iconData: Symbols.arrow_back_rounded,
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
                    style: AppText.defaultTheme.headlineMedium.copyWith(
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
                    child: Tabs.surface(
                      currentTabIndex: _currentTabIndex,
                      onTabChanged: (index) =>
                          setState(() => _currentTabIndex = index),
                      tabs: [
                        Tab(
                          title: AppLocalizations.of(context)!.settingsTabTitle,
                          icon: Symbols.settings_rounded,
                        ),
                        Tab(
                          title: AppLocalizations.of(
                            context,
                          )!.installedContentTitle,
                          icon: Symbols.inventory_2_rounded,
                        ),
                      ],
                    ),
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

  Widget _buildSettingsTab() {
    final settingsRepo = context.watch<SettingsRepository>();
    final l10n = AppLocalizations.of(context)!;

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
                      title: l10n.settingsWindowResolution,
                      description: l10n.settingsWindowResolutionDesc,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 16,
                            children: [
                              Expanded(
                                child: TextField(
                                  labelText: l10n.settingsWidth,
                                  hintText: l10n.inheritsGlobalSetting,
                                  controller: _widthController,
                                  width: double.infinity,
                                ),
                              ),
                              Text(
                                'x',
                                style: AppText.defaultTheme.titleLarge.copyWith(
                                  color: AppColors.dark.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  labelText: l10n.settingsHeight,
                                  hintText: l10n.inheritsGlobalSetting,
                                  controller: _heightController,
                                  width: double.infinity,
                                ),
                              ),
                            ],
                          ),
                          if (_widthController.text.isEmpty &&
                              _heightController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                l10n.inheritsGlobalSettingDesc(
                                  '${settingsRepo.windowWidth}x${settingsRepo.windowHeight}',
                                ),
                                style: AppText.defaultTheme.labelSmall.copyWith(
                                  color: AppColors.dark.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
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
                      title: l10n.settingsMaxMemory,
                      description: l10n.settingsMaxMemoryDesc,
                      child: _buildMemorySliderSection(settingsRepo, l10n),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFormSection(
                  title: l10n.deleteInstanceTitle,
                  iconData: Symbols.delete_rounded,
                  children: [
                    _buildSettingsRow(
                      title: l10n.deleteInstanceTitle,
                      description: l10n.deleteInstanceContent,
                      child: Row(
                        children: [
                          Button.error(
                            l10n.deleteButton,
                            onPressed: _deleteInstance,
                            iconData: Symbols.delete_rounded,
                          ),
                        ],
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isSaving)
                CircularProgressIndicator.primary(size: 24)
              else
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Tooltip(
                        message: l10n.resetToDefaultsButton,
                        child: IconButton.surface(
                          onPressed: _resetToDefaults,
                          iconData: Symbols.refresh_rounded,
                        ),
                      ),
                      Button.primary(
                        l10n.saveChangesButton,
                        onPressed: _saveSettings,
                        iconData: Symbols.save_rounded,
                      ),
                    ],
                  ),
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
          style: AppText.defaultTheme.headlineMedium.copyWith(
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
                style: AppText.defaultTheme.titleMedium.copyWith(
                  color: AppColors.dark.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppText.defaultTheme.bodyMedium.copyWith(
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
                  style: AppText.defaultTheme.headlineSmall.copyWith(
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

  Widget _buildMemorySliderSection(
    SettingsRepository settingsRepo,
    AppLocalizations l10n,
  ) {
    final maxSliderMB = (_maxMemoryMB / 512).floor() * 512;
    final divisions = maxSliderMB ~/ 512;

    if (!_useInstanceMemory) {
      // Show "inherits global" mode
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.inheritsGlobalSettingDesc(
              '${settingsRepo.javaMemory} ${l10n.settingsMB}',
            ),
            style: AppText.defaultTheme.bodyMedium.copyWith(
              color: AppColors.dark.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _useInstanceMemory = true;
                  _memorySliderValue = settingsRepo.javaMemory.toDouble();
                });
              },
              child: Text(
                l10n.overrideGlobalSetting,
                style: AppText.defaultTheme.titleMedium.copyWith(
                  color: AppColors.dark.primary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show custom slider
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSlider(
          min: 512,
          max: maxSliderMB.toDouble(),
          value: (_memorySliderValue ?? settingsRepo.javaMemory.toDouble())
              .clamp(512, maxSliderMB.toDouble()),
          divisions: divisions > 0 ? divisions : 1,
          valueLabelBuilder: (v) => '${v.toInt()} ${l10n.settingsMB}',
          onChanged: (v) {
            setState(() => _memorySliderValue = v);
          },
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _useInstanceMemory = false;
                _memorySliderValue = null;
              });
            },
            child: Text(
              l10n.useGlobalSetting,
              style: AppText.defaultTheme.titleMedium.copyWith(
                color: AppColors.dark.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab() {
    if (_isLoadingContent && _allContentItems.isEmpty) {
      return Center(child: CircularProgressIndicator.primary());
    }

    final allDisplayedSelected =
        _displayItems.isNotEmpty &&
        _displayItems.every((item) => _selectedMods.contains(item.filename));

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
              style: AppText.defaultTheme.headlineMedium.copyWith(
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
                  labelText: AppLocalizations.of(context)!.searchHint,
                  isSearchField: true,
                ),
              ),
              const SizedBox(width: 16),
              Button.surface(
                _isSelectionMode ? AppLocalizations.of(context)!.cancelSelection : AppLocalizations.of(context)!.selectContent,
                iconData: _isSelectionMode
                    ? Symbols.close_rounded
                    : Symbols.checklist_rounded,
                onPressed: () {
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) {
                      _selectedMods.clear();
                    }
                  });
                },
              ),
              if (_isSelectionMode) ...[
                const SizedBox(width: 16),
                Button.surface(
                  allDisplayedSelected ? AppLocalizations.of(context)!.deselectAll : AppLocalizations.of(context)!.selectAllButton,
                  iconData: allDisplayedSelected
                      ? Symbols.deselect_rounded
                      : Symbols.select_all_rounded,
                  onPressed: () {
                    setState(() {
                      if (allDisplayedSelected) {
                        for (var item in _displayItems) {
                          _selectedMods.remove(item.filename);
                        }
                      } else {
                        for (var item in _displayItems) {
                          _selectedMods.add(item.filename);
                        }
                      }
                    });
                  },
                ),
              ],
              const SizedBox(width: 16),
              Button.surface(
                _sortAscending ? AppLocalizations.of(context)!.sortAZ : AppLocalizations.of(context)!.sortZA,
                iconData: _sortAscending
                    ? Symbols.sort_by_alpha_rounded
                    : Symbols.sort_rounded,
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _applyFilters();
                  });
                },
              ),
              if (_isSelectionMode) ...[
                const SizedBox(width: 16),
                Button.error(
                  AppLocalizations.of(context)!.deleteSelectedContent(_selectedMods.length),
                  iconData: Symbols.delete_rounded,
                  onPressed: _selectedMods.isNotEmpty
                      ? _deleteSelectedMods
                      : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
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
                  Expanded(
                    child: _displayItems.isEmpty && !_isLoadingContent
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.noResultsFound,
                              style: AppText.defaultTheme.headlineMedium.copyWith(
                                color: AppColors.dark.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _displayItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _displayItems[index];

                              String typeLabel;
                              switch (item.type.toLowerCase()) {
                                case 'mod': typeLabel = AppLocalizations.of(context)!.contentTypeMod; break;
                                case 'resourcepack': typeLabel = AppLocalizations.of(context)!.contentTypeResourcepack; break;
                                case 'datapack': typeLabel = AppLocalizations.of(context)!.contentTypeDatapack; break;
                                case 'modpack': typeLabel = AppLocalizations.of(context)!.contentTypeModpack; break;
                                case 'shader': typeLabel = AppLocalizations.of(context)!.contentTypeShader; break;
                                default: typeLabel = item.type.toUpperCase();
                              }

                              Widget? iconWidget;
                              if (item.model?.iconUrl != null &&
                                  item.model!.iconUrl!.isNotEmpty) {
                                iconWidget = ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.model!.iconUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            width: 48,
                                            height: 48,
                                            color: AppColors
                                                .dark
                                                .surfaceContainerHighest,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator.primary(
                                                    size: 24,
                                                  ),
                                            ),
                                          );
                                        },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 48,
                                              height: 48,
                                              color: AppColors
                                                  .dark
                                                  .surfaceContainerHighest,
                                              child: Icon(
                                                item.type == 'resourcepack'
                                                    ? Symbols.palette_rounded
                                                    : Symbols.extension_rounded,
                                                color: AppColors
                                                    .dark
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                  ),
                                );
                              } else {
                                iconWidget = Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.dark.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.type == 'resourcepack'
                                        ? Symbols.palette_rounded
                                        : Symbols.extension_rounded,
                                    color: AppColors.dark.onSurfaceVariant,
                                  ),
                                );
                              }

                              return ListItem.primary(
                                title:
                                    item.model?.title ??
                                    item.filename.replaceAll('.disabled', ''),
                                subtitle: item.isManaged
                                    ? AppLocalizations.of(context)!.byAuthor(item.model?.author ?? '')
                                    : '${item.filename}${!item.fileExists ? ' (${AppLocalizations.of(context)!.missingFile})' : ''}',
                                isSelected:
                                    _isSelectionMode &&
                                    _selectedMods.contains(item.filename),
                                onTap: _isSelectionMode
                                    ? () {
                                        setState(() {
                                          if (_selectedMods.contains(
                                            item.filename,
                                          )) {
                                            _selectedMods.remove(item.filename);
                                          } else {
                                            _selectedMods.add(item.filename);
                                          }
                                        });
                                      }
                                    : null,
                                leadingWidget: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isSelectionMode) ...[
                                      CoreCheckbox(
                                        value: _selectedMods.contains(
                                          item.filename,
                                        ),
                                        label: '',
                                        onChanged: (val) {
                                          setState(() {
                                            if (_selectedMods.contains(
                                              item.filename,
                                            )) {
                                              _selectedMods.remove(
                                                item.filename,
                                              );
                                            } else {
                                              _selectedMods.add(item.filename);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    iconWidget,
                                  ],
                                ),
                                chip: item.isManaged
                                    ? null
                                    : Chip.surface(
                                        AppLocalizations.of(
                                          context,
                                        )!.manualInstalled,
                                        iconData: Symbols.folder_rounded,
                                      ),
                                tags: [
                                  Chip.tertiary(
                                    typeLabel,
                                    iconData: item.type == 'resourcepack'
                                        ? Symbols.palette_rounded
                                        : Symbols.extension_rounded,
                                  ),
                                  if (item.isManaged &&
                                      item.model?.version != null)
                                    Chip.surface('v${item.model!.version}'),
                                ],
                                trailingWidget: SwitchButton(
                                  value: !item.isDisabled,
                                  onChanged: (value) => _toggleContent(item),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedMods() async {
    if (_selectedMods.isEmpty) return;

    final itemsToDelete = _allContentItems
        .where((item) => _selectedMods.contains(item.filename))
        .toList();
    final instanceRepo = context.read<InstanceRepository>();
    final appData = await getApplicationSupportDirectory();
    List<InstalledContentModel> newContent = widget.instance.installedContent
        .toList();

    for (final item in itemsToDelete) {
      final folderName = switch (item.type) {
        'resourcepack' => 'resourcepacks',
        'shader' => 'shaderpacks',
        _ => 'mods',
      };
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

      if (item.isManaged && item.model != null) {
        newContent.removeWhere(
          (c) =>
              c.projectId == item.model!.projectId &&
              c.versionId == item.model!.versionId,
        );
      }
    }

    final updatedInstance = widget.instance.copyWith(
      installedContent: newContent,
    );
    await instanceRepo.saveInstance(updatedInstance);

    if (mounted) {
      context.read<InstanceScreenViewModel>().loadInstances.execute();
    }

    _selectedMods.clear();
    _loadContent(showLoader: false); // Reload local list
  }

  Future<void> _toggleContent(_DisplayContent item) async {
    final instanceRepo = context.read<InstanceRepository>();
    final folderName = switch (item.type) {
      'resourcepack' => 'resourcepacks',
      'shader' => 'shaderpacks',
      _ => 'mods',
    };
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
          if (c.projectId == item.model!.projectId &&
              c.versionId == item.model!.versionId) {
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

      _loadContent(showLoader: false);
    }
  }
}
