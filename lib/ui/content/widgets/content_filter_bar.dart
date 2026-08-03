import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/ui/core/checkbox.dart';
import 'package:yelauncher/ui/core/dropdown.dart';
import 'package:yelauncher/ui/core/multi_select_dropdown.dart';

class ContentFilterBar extends StatelessWidget {
  final ContentScreenViewModel viewModel;

  const ContentFilterBar({super.key, required this.viewModel});

  String _getCategoryLabel(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'adventure':
        return l10n.categoryAdventure;
      case 'magic':
        return l10n.categoryMagic;
      case 'technology':
        return l10n.categoryTechnology;
      case 'optimization':
        return l10n.categoryOptimization;
      case 'utility':
        return l10n.categoryUtility;
      case 'decoration':
        return l10n.categoryDecoration;
      case 'worldgen':
        return l10n.categoryWorldgen;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // We only show mod loaders for mods and modpacks
    final showModLoaderFilter =
        viewModel.projectType == 'mod' || viewModel.projectType == 'modpack';

    return Selector<ContentScreenViewModel, _FilterState>(
      selector: (_, vm) => _FilterState(
        selectedVersions: vm.selectedVersions,
        selectedModLoaders: vm.selectedModLoaders,
        selectedCategories: vm.selectedCategories,
        sortOrder: vm.sortOrder,
        showSnapshots: vm.showSnapshots,
        availableVersions: vm.availableVersions,
        availableModLoaders: vm.availableModLoaders,
        availableCategories: vm.availableCategories,
        projectType: vm.projectType,
      ),
      builder: (context, state, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            spacing: 16,
            children: [
              // VERSION FILTER
              MultiSelectDropdown<String>(
                iconData: Symbols.build_circle_rounded,
                emptyLabel: l10n.filterAllVersions,
                values: state.selectedVersions,
                items: state.availableVersions
                    .map((v) => MultiSelectDropdownItem(value: v, label: v))
                    .toList(),
                onToggle: viewModel.toggleVersion,
              ),

              // SHOW SNAPSHOTS
              CoreCheckbox(
                value: state.showSnapshots,
                onChanged: (value) =>
                    viewModel.toggleShowSnapshots(value ?? false),
                label: l10n.showSnapshots,
              ),

              // MOD LOADER FILTER
              if (showModLoaderFilter)
                MultiSelectDropdown<String>(
                  iconData: Symbols.extension_rounded,
                  emptyLabel: l10n.filterAllLoaders,
                  values: state.selectedModLoaders,
                  items: state.availableModLoaders
                      .map(
                        (l) => MultiSelectDropdownItem(
                          value: l,
                          label: l[0].toUpperCase() + l.substring(1),
                        ),
                      )
                      .toList(),
                  onToggle: viewModel.toggleModLoader,
                ),

              // CATEGORY FILTER
              MultiSelectDropdown<String>(
                iconData: Symbols.category_rounded,
                emptyLabel: l10n.filterAllCategories,
                values: state.selectedCategories,
                items: state.availableCategories
                    .map(
                      (c) => MultiSelectDropdownItem(
                        value: c,
                        label: _getCategoryLabel(context, c),
                      ),
                    )
                    .toList(),
                onToggle: viewModel.toggleCategory,
              ),

              // SORT ORDER
              Dropdown<String>(
                iconData: Symbols.sort_rounded,
                value: state.sortOrder,
                items: [
                  DropdownItem(value: 'relevance', label: l10n.sortRelevance),
                  DropdownItem(value: 'downloads', label: l10n.sortDownloads),
                  DropdownItem(value: 'newest', label: l10n.sortNewest),
                  DropdownItem(value: 'updated', label: l10n.sortUpdated),
                ],
                onChanged: viewModel.setSortOrder,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterState {
  final List<String> selectedVersions;
  final List<String> selectedModLoaders;
  final List<String> selectedCategories;
  final String sortOrder;
  final bool showSnapshots;
  final List<String> availableVersions;
  final List<String> availableModLoaders;
  final List<String> availableCategories;
  final String projectType;

  _FilterState({
    required this.selectedVersions,
    required this.selectedModLoaders,
    required this.selectedCategories,
    required this.sortOrder,
    required this.showSnapshots,
    required this.availableVersions,
    required this.availableModLoaders,
    required this.availableCategories,
    required this.projectType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FilterState &&
          runtimeType == other.runtimeType &&
          listEquals(selectedVersions, other.selectedVersions) &&
          listEquals(selectedModLoaders, other.selectedModLoaders) &&
          listEquals(selectedCategories, other.selectedCategories) &&
          sortOrder == other.sortOrder &&
          showSnapshots == other.showSnapshots &&
          projectType == other.projectType &&
          listEquals(availableVersions, other.availableVersions);

  @override
  int get hashCode =>
      selectedVersions.hashCode ^
      selectedModLoaders.hashCode ^
      selectedCategories.hashCode ^
      sortOrder.hashCode ^
      showSnapshots.hashCode ^
      projectType.hashCode ^
      availableVersions.hashCode;

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
