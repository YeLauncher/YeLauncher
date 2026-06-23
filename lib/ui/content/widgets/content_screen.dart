import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_detail_dialog.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/card.dart';
import 'package:yelauncher/ui/core/loading_indicator.dart';
import 'package:yelauncher/ui/core/text_field.dart' as core_text_field;
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/ui/core/icon_button.dart';
import 'package:yelauncher/ui/content/widgets/content_install_dialog.dart';

typedef DisplayItem = ({
  String title,
  String description,
  String? iconUrl,
  String? authorName,
  ContentItem? originalItem,
});

final List<DisplayItem> _skeletonItems = List.generate(
  12,
  (_) => (
    title: 'Placeholder title',
    description: 'Placeholder description text here',
    iconUrl: null,
    authorName: 'Loading Author',
    originalItem: null,
  ),
);

class ContentScreen extends StatefulWidget {
  final ContentScreenViewModel viewModel;

  const ContentScreen({super.key, required this.viewModel});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _projectTypes = [
    'mod',
    'resourcepack',
    'datapack',
    'modpack',
  ];
  final List<String> _tabLabels = ['Моди', 'Ресурспаки', 'Датапаки', 'Модпаки'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.viewModel.setQuery(_searchController.text);
    });

    _scrollController.addListener(_onScroll);
    widget.viewModel.search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.viewModel.loadMore();
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    widget.viewModel.setProjectType(_projectTypes[index]);
  }

  void _showInfoDialog(BuildContext context, ContentItem item) {
    final viewModel = ContentDetailViewModel(
      item: item,
      contentRepository: context.read<ContentRepository>(),
      instanceRepository: context.read<InstanceRepository>(),
    );
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (context, anim1, anim2) =>
          Center(child: ContentDetailDialog(viewModel: viewModel)),
    );
  }

  void _showInstallDialog(BuildContext context, ContentItem item) async {
    final viewModel = ContentDetailViewModel(
      item: item,
      contentRepository: context.read<ContentRepository>(),
      instanceRepository: context.read<InstanceRepository>(),
    );

    // show loading dialog or just load it silently? Since it's quick, let's load it and then show the dialog.
    // To provide feedback, we could just show the detail dialog if versions are not ready, or a loading overlay.
    // For simplicity, we just await it.
    await viewModel.loadDetails();
    if (viewModel.versions.isNotEmpty && context.mounted) {
      ContentVersion? bestVersion;
      for (final v in viewModel.versions) {
        if (viewModel.getCompatibleInstances(v).isNotEmpty) {
          bestVersion = v;
          break;
        }
      }
      bestVersion ??= viewModel.versions.first;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        pageBuilder: (context, anim1, anim2) => Center(
          child: ContentInstallDialog(
            viewModel: viewModel,
            version: bestVersion!,
          ),
        ),
      );
    } else if (context.mounted) {
      // Fallback if no versions or if modpack (which currently returns empty compatible instances or we handle differently)
      _showInfoDialog(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Container(
        color: AppColors.dark.surface,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Контент",
              style: AppText.defaultTheme.titleLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            core_text_field.TextField(
              controller: _searchController,
              labelText: 'Пошук...',
              width: double.infinity,
            ),
            const SizedBox(height: 16),
            Row(
              spacing: 8,
              children: List.generate(_tabLabels.length, (index) {
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
                      _tabLabels[index],
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
              child: Consumer<ContentScreenViewModel>(
                builder: (context, viewModel, child) {
                  final isLoading = viewModel.isLoading;
                  final List<DisplayItem> displayItems = isLoading
                      ? _skeletonItems
                      : viewModel.items
                            .map<DisplayItem>(
                              (item) => (
                                title: item.title,
                                description: item.description,
                                iconUrl: item.iconUrl,
                                authorName: item.author ?? item.organization ?? item.teamId,
                                originalItem: item,
                              ),
                            )
                            .toList();

                  if (!isLoading && viewModel.items.isEmpty) {
                    return Center(
                      child: Text(
                        "Нічого не знайдено",
                        style: AppText.defaultTheme.body.copyWith(
                          color: AppColors.dark.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  // 1. Distribute items sequentially across N columns to handle varied heights
                  const int columnsCount = 3;
                  final List<List<dynamic>> columnItems = List.generate(
                    columnsCount,
                    (_) => [],
                  );
                  for (int i = 0; i < displayItems.length; i++) {
                    columnItems[i % columnsCount].add(displayItems[i]);
                  }

                  return Skeletonizer(
                    enabled: isLoading,
                    // 2. Custom styling overrides to create deep black skeleton loaders
                    containersColor: const Color(0xFF000000),
                    effect: const ShimmerEffect(
                      baseColor: Color(0xFF121212),
                      highlightColor: Color(0xFF282828),
                    ),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: SizedBox.expand(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pure masonry column layout
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    int colIndex = 0;
                                    colIndex < columnsCount;
                                    colIndex++
                                  ) ...[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          for (final item
                                              in columnItems[colIndex]) ...[
                                            Card(
                                              title: item.title,
                                              subtitle: item.authorName != null ? 'by ${item.authorName}' : null,
                                              description: item.description,
                                              imageUrl: item.iconUrl,
                                              maxWidth: 500,
                                              maxHeight: 500,
                                              minWidth: 0,
                                              minHeight: 0,
                                              buttons: [
                                                IconButton.surface(
                                                  iconData: Symbols.info,
                                                  onPressed:
                                                      item.originalItem == null
                                                      ? () {}
                                                      : () {
                                                          _showInfoDialog(
                                                            context,
                                                            item.originalItem!,
                                                          );
                                                        },
                                                ),
                                                Button.primary(
                                                  'Add',
                                                  onPressed:
                                                      item.originalItem == null
                                                      ? () {}
                                                      : () {
                                                          _showInstallDialog(
                                                            context,
                                                            item.originalItem!,
                                                          );
                                                        },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Vertical item gap
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (colIndex < columnsCount - 1)
                                      const SizedBox(width: 8),
                                    // Horizontal column gap
                                  ],
                                ],
                              ),
                              if (viewModel.isLoadingMore)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: LoadingIndicator.secondary(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
