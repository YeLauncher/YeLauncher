import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/content/view_models/content_screen_viewmodel.dart';
import 'package:yelauncher/ui/content/widgets/content_filter_bar.dart';
import 'package:yelauncher/ui/content/widgets/content_card.dart';
import 'package:yelauncher/ui/core/loading_indicator.dart';
import 'package:yelauncher/ui/core/text_field.dart' as core_text_field;
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:yelauncher/l10n/app_localizations.dart';

final List<ContentItem> _skeletonItems = List.generate(
  12,
  (_) => const ContentItem(
    id: 'skeleton',
    slug: 'skeleton',
    title: 'Placeholder title text',
    description: 'Placeholder description text here',
    projectType: 'mod',
    author: 'Loading Author',
    downloads: 1000000,
    gameVersions: ['1.20.1'],
    loaders: ['Fabric'],
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
    'shader',
  ];
  int _selectedTabIndex = 0;

  List<String> _getTabLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.tabMods, l10n.tabResourcepacks, l10n.tabDatapacks, l10n.tabModpacks, l10n.tabShaders];
  }

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

  void _showInstallDialog(BuildContext context, ContentItem item) async {
    final viewModel = ContentDetailViewModel(
      item: item,
      contentRepository: context.read<ContentRepository>(),
      instanceRepository: context.read<InstanceRepository>(),
    );

    // Just push to the detail page.
    if (context.mounted) {
      context.push(Routes.contentDetail, extra: {
        'viewModel': viewModel,
        'targetVersion': null,
      });
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
              AppLocalizations.of(context)!.contentTab,
              style: AppText.defaultTheme.titleLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            core_text_field.TextField(
              key: const ValueKey('content_search_input'),
              controller: _searchController,
              labelText: AppLocalizations.of(context)!.searchHint,
              width: double.infinity,
              isSearchField: true,
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
            ContentFilterBar(viewModel: widget.viewModel),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ContentScreenViewModel>(
                builder: (context, viewModel, child) {
                  final isLoading = viewModel.isLoading;
                  final List<ContentItem> displayItems = isLoading
                      ? _skeletonItems
                      : viewModel.items;

                  if (!isLoading && viewModel.items.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.nothingFound,
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
                                            ContentCard(
                                              item: item,
                                              onTap: () {
                                                if (!isLoading && item.id != 'skeleton') {
                                                  _showInstallDialog(context, item);
                                                }
                                              },
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
