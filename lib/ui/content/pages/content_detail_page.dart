import 'dart:io';

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:yelauncher/config/assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:yelauncher/routing/routes.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/core/checkbox.dart';
import 'package:yelauncher/ui/core/chip.dart';
import 'package:yelauncher/data/repositories/instances/instance_styling_repository.dart';
import 'package:yelauncher/ui/core/icon_button.dart';

import 'package:yelauncher/ui/core/multi_select_dropdown.dart';
import 'package:yelauncher/ui/core/tabs.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yelauncher/data/repositories/instances/instance_repository.dart';
import 'package:yelauncher/data/services/download_service.dart';
import 'package:yelauncher/domain/models/content/content_version.dart';
import 'package:yelauncher/domain/models/content/content_file.dart';
import 'package:yelauncher/domain/models/download/download_model.dart';
import 'package:yelauncher/domain/models/instance/installed_content_model.dart';
import 'package:yelauncher/domain/models/instance/instance_model.dart';
import 'package:yelauncher/ui/content/view_models/content_detail_viewmodel.dart';
import 'package:yelauncher/ui/core/button.dart';
import 'package:yelauncher/ui/core/list_item.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/data/repositories/content/content_repository.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/domain/models/content/resolved_dependency.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/ui/core/circular_progress_indicator.dart';
import 'package:yelauncher/ui/core/tooltip.dart';
import 'package:logging/logging.dart';

class ContentDetailPage extends StatefulWidget {
  final ContentDetailViewModel viewModel;
  final ContentVersion? targetVersion;

  const ContentDetailPage({
    super.key,
    required this.viewModel,
    this.targetVersion,
  });

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  InstanceModel? selectedInstance;
  bool isInstalling = false;
  String? errorMessage;

  int _currentDownloadedBytes = 0;
  int? _currentTotalBytes;

  final _log = Logger('ContentDetailPage');
  List<ResolvedDependency> resolvedDependencies = [];
  bool isResolvingDependencies = false;

  int _selectedTabIndex = 0;
  final List<String> _selectedGameVersions = [];
  bool _showSnapshots = false;
  bool _installRequiredDependencies = true;

  String? _getLoaderIcon(String loader) {
    final lower = loader.toLowerCase();
    if (lower == 'fabric' || lower == 'quilt') return Assets.fabricLogo;
    if (lower == 'forge' || lower == 'neoforge') return Assets.forgeLogo;
    return null;
  }

  Widget _buildInstanceIcon(InstanceModel instance, BuildContext context) {
    final instanceColor = instance.color;
    final instanceIcon = instance.icon;

    final stylingRepository = context.read<InstanceStylingRepository>();

    final bgColor = stylingRepository.getColor(
      instanceColor,
      fallback: AppColors.dark.primaryContainer,
    );
    final iconColor = instanceColor != null
        ? const Color(0xFFFFFFFF)
        : AppColors.dark.primary;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        stylingRepository.getIconData(instanceIcon),
        color: iconColor,
        size: 20,
      ),
    );
  }

  List<Tab> _getTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Tab(title: l10n.tabDescription),
      Tab(title: l10n.tabGallery),
      Tab(title: l10n.tabVersions),
      Tab(title: l10n.tabDependencies),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadDetails();
    _loadFreshInstances();
  }

  Future<void> _loadFreshInstances() async {
    final repo = context.read<InstanceRepository>();
    final allInstances = await repo.getInstances();
    if (mounted) {
      setState(() {
        widget.viewModel.instances = allInstances;
      });
    }
  }

  Future<void> _resolveDependencies(InstanceModel instance) async {
    setState(() {
      isResolvingDependencies = true;
      resolvedDependencies = [];
    });

    final repo = context.read<ContentRepository>();
    final resolved = <ResolvedDependency>[];
    final visited = <String>{};

    Future<void> resolve(ContentVersion version) async {
      if (version.dependencies == null) return;

      for (final dep in version.dependencies!) {
        if (dep.dependencyType != 'required') continue;
        if (dep.projectId == null && dep.versionId == null) continue;

        final checkId = dep.projectId ?? dep.versionId!;
        if (visited.contains(checkId)) continue;
        visited.add(checkId);

        ContentVersion? depVersion;

        if (dep.versionId != null) {
          final res = await repo.getVersion(dep.versionId!);
          if (res is Success<ContentVersion>) {
            depVersion = res.value;
          }
        } else if (dep.projectId != null) {
          final res = await repo.getVersions(dep.projectId!);
          if (res is Success<List<ContentVersion>>) {
            final loaderLower = instance.modLoader.toLowerCase();
            for (final v in res.value) {
              if (v.gameVersions.contains(instance.minecraftVersion) &&
                  (v.loaders.contains(loaderLower) ||
                      (loaderLower == 'quilt' &&
                          v.loaders.contains('fabric')))) {
                depVersion = v;
                break;
              }
            }
          }
        }

        if (depVersion != null) {
          final itemRes = await repo.getContent(depVersion.projectId);
          if (itemRes is Success<ContentItem>) {
            resolved.add(
              ResolvedDependency(item: itemRes.value, version: depVersion),
            );
            await resolve(depVersion);
          }
        }
      }
    }

    try {
      final vToResolve =
          widget.targetVersion ??
          widget.viewModel.getBestVersionForInstance(instance);
      if (vToResolve != null) {
        await resolve(vToResolve);
      }
    } catch (e) {
      _log.warning('Error resolving dependencies: $e');
    }

    if (mounted && selectedInstance == instance) {
      setState(() {
        resolvedDependencies = resolved;
        isResolvingDependencies = false;
      });
    }
  }

  Future<void> _install() async {
    setState(() {
      isInstalling = true;
      errorMessage = null;
    });

    try {
      final downloadService = context.read<DownloadService>();
      final instanceRepo = context.read<InstanceRepository>();
      final allInstances = await instanceRepo.getInstances();
      final currentInstance = allInstances.firstWhere(
        (i) => i.id == selectedInstance!.id,
      );

      final newInstalledContent = List<InstalledContentModel>.from(
        currentInstance.installedContent,
      );

      Future<void> downloadAndInstall(
        ContentItem item,
        ContentVersion version,
      ) async {
        if (newInstalledContent.any(
          (c) => c.projectId == item.id && c.versionId == version.id,
        )) {
          return;
        }

        final type = item.projectType;
        ContentFile? file;

        if (type == 'mod' && selectedInstance != null) {
          final loader = selectedInstance!.modLoader.toLowerCase();
          if (loader.isNotEmpty && loader != 'none' && loader != 'vanilla') {
            for (final f in version.files) {
              if (f.filename.toLowerCase().contains(loader)) {
                file = f;
                break;
              }
            }
          }
        }

        file ??= version.files.firstWhere(
          (f) => f.primary,
          orElse: () => version.files.first,
        );

        final url = file.url;
        final fileName = Uri.decodeFull(file.filename);

        final folderName = switch (type) {
          'resourcepack' => 'resourcepacks',
          'shader' => 'shaderpacks',
          _ => 'mods',
        };
        final relativePath =
            'instances/${selectedInstance!.id}/$folderName/$fileName';

        await downloadService.downloadIfMissing(
          DownloadModel(url: url, path: relativePath, sha1: ''),
          onProgress: (downloaded, total) {
            if (mounted) {
              setState(() {
                _currentDownloadedBytes = downloaded;
                _currentTotalBytes = total;
              });
            }
          },
        );

        // Remove existing installed content if present
        final existingIndex = newInstalledContent.indexWhere(
          (c) => c.projectId == item.id,
        );
        if (existingIndex != -1) {
          final oldContent = newInstalledContent[existingIndex];
          final appData = await getApplicationSupportDirectory();
          final oldFile = File(
            p.join(
              appData.path,
              'instances',
              selectedInstance!.id,
              folderName,
              Uri.decodeFull(oldContent.filename),
            ),
          );

          if (await oldFile.exists()) {
            await oldFile.delete();
          }
          final disabledOldFile = File('${oldFile.path}.disabled');
          if (await disabledOldFile.exists()) {
            await disabledOldFile.delete();
          }
          newInstalledContent.removeAt(existingIndex);
        }

        final content = InstalledContentModel(
          projectId: item.id,
          versionId: version.id,
          filename: Uri.decodeFull(fileName),
          title: item.title,
          type: type,
          author: item.author ?? 'Unknown Author',
          version: version.versionNumber,
          iconUrl: item.iconUrl,
        );
        newInstalledContent.add(content);
      }

      // Install main mod
      final mainVersionToInstall =
          widget.targetVersion ??
          widget.viewModel.getBestVersionForInstance(currentInstance);
      if (mainVersionToInstall == null) {
        throw Exception('No compatible version found for this instance.');
      }

      await downloadAndInstall(widget.viewModel.item, mainVersionToInstall);

      // Install all resolved dependencies
      if (_installRequiredDependencies) {
        for (final dep in resolvedDependencies) {
          await downloadAndInstall(dep.item, dep.version);
        }
      }

      final updatedInstance = currentInstance.copyWith(
        installedContent: newInstalledContent,
      );
      await instanceRepo.saveInstance(updatedInstance);

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(
          context,
        )!.errorWithParam(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          isInstalling = false;
          _currentDownloadedBytes = 0;
          _currentTotalBytes = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.viewModel,
      child: Consumer<ContentDetailViewModel>(
        builder: (context, vm, child) {
          final compatibleInstances = widget.targetVersion != null
              ? vm.getCompatibleInstances(widget.targetVersion!).toList()
              : vm.instances
                    .where((i) => vm.getBestVersionForInstance(i) != null)
                    .toList();

          compatibleInstances.sort((a, b) {
            final vA = widget.targetVersion ?? vm.getBestVersionForInstance(a)!;
            final aInstalled = a.installedContent.any(
              (c) => c.projectId == vm.item.id && c.versionId == vA.id,
            );

            final vB = widget.targetVersion ?? vm.getBestVersionForInstance(b)!;
            final bInstalled = b.installedContent.any(
              (c) => c.projectId == vm.item.id && c.versionId == vB.id,
            );

            if (aInstalled == bInstalled) return a.name.compareTo(b.name);
            return aInstalled ? 1 : -1;
          });

          bool isAlreadyInstalled = false;
          ContentVersion? versionToInstall;
          if (selectedInstance != null) {
            versionToInstall =
                widget.targetVersion ??
                vm.getBestVersionForInstance(selectedInstance!);
            if (versionToInstall != null) {
              isAlreadyInstalled = selectedInstance!.installedContent.any(
                (content) =>
                    content.projectId == vm.item.id &&
                    content.versionId == versionToInstall!.id,
              );
            }
          }

          return Container(
            color: AppColors.dark.surface,
            child: Stack(
              children: [
                // Background graphic/glow
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dark.primary.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dark.primary.withValues(alpha: 0.2),
                          blurRadius: 100,
                          spreadRadius: 100,
                        ),
                      ],
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Panel: Mod Info
                            Expanded(flex: 6, child: _buildLeftPanel(context)),

                            // Right Panel: Instances & Install
                            Expanded(
                              flex: 4,
                              child: _buildRightPanel(
                                context,
                                compatibleInstances,
                                isAlreadyInstalled,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton.surface(
            iconData: Symbols.arrow_back_rounded,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.installButton,
            style: AppText.defaultTheme.headlineMedium.copyWith(
              color: AppColors.dark.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, bottom: 24, right: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.dark.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'content_icon_${widget.viewModel.item.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: (widget.viewModel.item.iconUrl?.isEmpty ?? true)
                      ? Container(
                          width: 80,
                          height: 80,
                          color: AppColors.dark.surfaceContainerHighest,
                          child: Icon(
                            Symbols.broken_image_rounded,
                            size: 40,
                            color: AppColors.dark.onSurfaceVariant,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.viewModel.item.iconUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Skeletonizer(
                                enabled: true,
                                containersColor:
                                    AppColors.dark.surfaceContainerHigh,
                                effect: ShimmerEffect(
                                  baseColor:
                                      AppColors.dark.surfaceContainerHighest,
                                  highlightColor:
                                      AppColors.dark.surfaceContainerHighest,
                                ),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.dark.surfaceContainerHighest,
                                ),
                              ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.dark.surfaceContainerHighest,
                            child: Icon(
                              Symbols.broken_image_rounded,
                              size: 40,
                              color: AppColors.dark.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.viewModel.item.title,
                      style: AppText.defaultTheme.headlineLarge.copyWith(
                        color: AppColors.dark.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChips(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Tabs.surface(
            tabs: _getTabs(context),
            currentTabIndex: _selectedTabIndex,
            onTabChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Skeletonizer(
              enabled: widget.viewModel.isLoading,
              containersColor: AppColors.dark.skeletonContainer,
              effect: ShimmerEffect(
                baseColor: AppColors.dark.skeletonBase,
                highlightColor: AppColors.dark.skeletonHighlight,
              ),
              child: Builder(
                builder: (context) {
                  if (_selectedTabIndex == 0) {
                    return _buildDescriptionTab();
                  } else if (_selectedTabIndex == 1) {
                    return _buildGalleryTab();
                  } else if (_selectedTabIndex == 2) {
                    return _buildVersionsTab();
                  } else {
                    return _buildDependenciesTab();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGameVersions(List<String> versions) {
    if (versions.isEmpty) return '';
    final releasePattern = RegExp(r'^\d+\.\d+(?:\.\d+)?$');
    final releases = versions.where((v) => releasePattern.hasMatch(v)).toList();
    if (releases.isEmpty) return '';
    if (releases.length == 1) return releases.first;
    return '${releases.first}-${releases.last}';
  }

  Widget _buildChips() {
    if (widget.viewModel.isLoading) {
      return Skeletonizer(
        enabled: true,
        containersColor: AppColors.dark.skeletonContainer,
        effect: ShimmerEffect(
          baseColor: AppColors.dark.skeletonBase,
          highlightColor: AppColors.dark.skeletonHighlight,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            4,
            (index) => Container(
              width: 80 + (index * 20.0),
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.dark.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      );
    }

    final item = widget.viewModel.fullItem ?? widget.viewModel.item;
    final authorName =
        item.author ??
        widget.viewModel.item.author ??
        item.organization ??
        item.teamId;

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
          for (final loader in item.loaders!)
            Chip.surface(loader, svgIcon: _getLoaderIcon(loader)),
      ],
    );
  }

  Widget _buildDescriptionTab() {
    if (widget.viewModel.isLoading) {
      return ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              height: 16,
              width: index % 4 == 3 ? 200 : double.infinity,
              decoration: BoxDecoration(
                color: AppColors.dark.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      );
    }

    final item = widget.viewModel.fullItem ?? widget.viewModel.item;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: item.body ?? item.description,
            styleSheet: MarkdownStyleSheet(
              p: AppText.defaultTheme.bodyLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
              h1: AppText.defaultTheme.headlineLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
              h2: AppText.defaultTheme.headlineMedium.copyWith(
                color: AppColors.dark.onSurface,
              ),
              h3: AppText.defaultTheme.titleLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
              h4: AppText.defaultTheme.titleMedium.copyWith(
                color: AppColors.dark.onSurface,
              ),
              h5: AppText.defaultTheme.labelLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
              h6: AppText.defaultTheme.labelSmall.copyWith(
                color: AppColors.dark.onSurfaceVariant,
              ),
              listBullet: AppText.defaultTheme.bodyLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
              a: AppText.defaultTheme.bodyLarge.copyWith(
                color: AppColors.dark.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (widget.viewModel.isLoading) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.dark.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      );
    }

    final item = widget.viewModel.fullItem;
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
          child: CachedNetworkImage(imageUrl: image.url, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildVersionsTab() {
    if (widget.viewModel.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.dark.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }

    if (widget.viewModel.versions.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.versionsNotFound,
          style: TextStyle(color: AppColors.dark.onSurface),
        ),
      );
    }

    final allGameVersions =
        widget.viewModel.versions.expand((v) => v.gameVersions).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    var filteredVersions = _selectedGameVersions.isEmpty
        ? widget.viewModel.versions
        : widget.viewModel.versions
              .where(
                (v) => v.gameVersions.any(
                  (gv) => _selectedGameVersions.contains(gv),
                ),
              )
              .toList();

    if (!_showSnapshots) {
      filteredVersions = filteredVersions
          .where((v) => v.versionType == 'release')
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: MultiSelectDropdown<String>(
                values: _selectedGameVersions,
                items: allGameVersions
                    .map((v) => MultiSelectDropdownItem(value: v, label: v))
                    .toList(),
                onToggle: (val) {
                  setState(() {
                    if (_selectedGameVersions.contains(val)) {
                      _selectedGameVersions.remove(val);
                    } else {
                      _selectedGameVersions.add(val);
                    }
                  });
                },
                emptyLabel: AppLocalizations.of(context)!.minecraftVersions,
                iconData: Symbols.filter_alt_rounded,
              ),
            ),
            const SizedBox(width: 16),
            CoreCheckbox(
              value: _showSnapshots,
              onChanged: (val) {
                setState(() {
                  _showSnapshots = val ?? false;
                });
              },
              label: AppLocalizations.of(context)!.showSnapshots,
            ),
            const SizedBox(width: 16),
            if (widget.targetVersion != null)
              Button.surface(
                AppLocalizations.of(context)!.clearSelection,
                iconData: Symbols.close_rounded,
                onPressed: () {
                  context.replace(
                    '${Routes.content}/${widget.viewModel.item.id}',
                    extra: {
                      'item': widget.viewModel.item,
                      'targetVersion': null,
                    },
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: filteredVersions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final version = filteredVersions[index];
              final isSelected = widget.targetVersion?.id == version.id;

              return ListItem.primary(
                title: version.versionNumber,
                isSelected: isSelected,
                tags: [
                  ...version.gameVersions.map(
                    (gv) => Chip.primary(gv, iconData: Symbols.gamepad_rounded),
                  ),
                  ...version.loaders.map(
                    (loader) =>
                        Chip.surface(loader, svgIcon: _getLoaderIcon(loader)),
                  ),
                ],
                onTap: () {
                  context.replace(
                    '${Routes.content}/${widget.viewModel.item.id}',
                    extra: {
                      'item': widget.viewModel.item,
                      'targetVersion': isSelected ? null : version,
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDependenciesTab() {
    if (widget.viewModel.isLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.dark.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }

    if (widget.viewModel.dependencies.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noDependenciesRequired,
          style: AppText.defaultTheme.bodyLarge.copyWith(
            color: AppColors.dark.onSurfaceVariant,
          ),
        ),
      );
    }

    final versionToUse =
        widget.targetVersion ??
        (widget.viewModel.versions.isNotEmpty
            ? widget.viewModel.versions.first
            : null);

    final requiredDeps = <ContentItem>[];
    final optionalDeps = <ContentItem>[];

    if (versionToUse?.dependencies != null) {
      for (final depItem in widget.viewModel.dependencies) {
        final depLink = versionToUse!.dependencies!
            .where((d) => d.projectId == depItem.id)
            .firstOrNull;
        if (depLink != null) {
          if (depLink.dependencyType == 'required') {
            requiredDeps.add(depItem);
          } else {
            optionalDeps.add(depItem);
          }
        } else {
          optionalDeps.add(depItem);
        }
      }
    } else {
      optionalDeps.addAll(widget.viewModel.dependencies);
    }

    Widget buildSection(String title, List<ContentItem> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Text(
              title,
              style: AppText.defaultTheme.titleMedium.copyWith(
                color: AppColors.dark.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...items.map(
            (dep) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListItem.secondary(
                title: dep.title,
                subtitle: dep.projectType,
                leadingWidget: dep.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: dep.iconUrl!,
                          width: 32,
                          height: 32,
                          errorWidget: (context, url, error) =>
                              const SizedBox(width: 32, height: 32),
                        ),
                      )
                    : const SizedBox(width: 32, height: 32),
                isSelected: false,
                trailingWidget: Icon(
                  Symbols.chevron_right_rounded,
                  color: AppColors.dark.onSurfaceVariant,
                ),
                onTap: () {
                  context.push(
                    '${Routes.content}/${dep.id}',
                    extra: {'item': dep},
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    return ListView(
      children: [
        buildSection(
          AppLocalizations.of(context)!.requiredDependencies,
          requiredDeps,
        ),
        buildSection(
          AppLocalizations.of(context)!.optionalDependencies,
          optionalDeps,
        ),
      ],
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    List<InstanceModel> compatibleInstances,
    bool isAlreadyInstalled,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 24, bottom: 24, left: 12),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectInstance,
                  style: AppText.defaultTheme.headlineMedium.copyWith(
                    color: AppColors.dark.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.selectInstanceSubtitle,
                  style: AppText.defaultTheme.bodyLarge.copyWith(
                    color: AppColors.dark.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: widget.viewModel.isLoading
                ? Skeletonizer(
                    enabled: true,
                    containersColor: AppColors.dark.skeletonContainer,
                    effect: ShimmerEffect(
                      baseColor: AppColors.dark.skeletonBase,
                      highlightColor: AppColors.dark.skeletonHighlight,
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      itemCount: 3,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return ListItem.secondary(
                          title: 'Loading Instance',
                          subtitle: 'Loading Version',
                          isSelected: false,
                          onTap: () {},
                        );
                      },
                    ),
                  )
                : compatibleInstances.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.noCompatibleInstances,
                      style: AppText.defaultTheme.bodyLarge.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: compatibleInstances.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final instance = compatibleInstances[index];
                      final isSelected = selectedInstance == instance;

                      final vForInst =
                          widget.targetVersion ??
                          widget.viewModel.getBestVersionForInstance(instance)!;
                      final isInstalled = instance.installedContent.any(
                        (content) =>
                            content.projectId == widget.viewModel.item.id &&
                            content.versionId == vForInst.id,
                      );

                      return Opacity(
                        opacity: isInstalled ? 0.5 : 1.0,
                        child: ListItem.secondary(
                          title: instance.name,
                          subtitle:
                              '${instance.minecraftVersion} - ${instance.modLoader}',
                          leadingWidget: _buildInstanceIcon(instance, context),
                          trailingIcon: Symbols.check_circle_rounded,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedInstance = instance;
                            });
                            _resolveDependencies(instance);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.dark.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: AppText.defaultTheme.bodyLarge.copyWith(
                      color: AppColors.dark.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (resolvedDependencies.isNotEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message: AppLocalizations.of(context)!
                                .installRequiredDependenciesTooltip(
                                  resolvedDependencies
                                      .map((e) => '- ${e.item.title}')
                                      .join('\n'),
                                ),
                            child: CoreCheckbox.secondary(
                              value: _installRequiredDependencies,
                              onChanged: (val) {
                                setState(() {
                                  _installRequiredDependencies = val ?? true;
                                });
                              },
                              label: AppLocalizations.of(
                                context,
                              )!.installRequiredDependencies,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInstalling) ...[
                          Tooltip(
                            message:
                                _currentTotalBytes != null &&
                                    _currentTotalBytes! > 0
                                ? AppLocalizations.of(
                                    context,
                                  )!.downloadProgress(
                                    (_currentDownloadedBytes / 1048576)
                                        .toStringAsFixed(2),
                                    (_currentTotalBytes! / 1048576)
                                        .toStringAsFixed(2),
                                  )
                                : AppLocalizations.of(
                                    context,
                                  )!.downloadProgressUnknownTotal(
                                    (_currentDownloadedBytes / 1048576)
                                        .toStringAsFixed(2),
                                  ),
                            child: CircularProgressIndicator.primary(
                              size: 24,
                              value:
                                  _currentTotalBytes != null &&
                                      _currentTotalBytes! > 0
                                  ? (_currentDownloadedBytes /
                                            _currentTotalBytes!)
                                        .clamp(0.0, 1.0)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Button.surface(
                          AppLocalizations.of(context)!.cancel,
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 12),
                        Button.primary(
                          isInstalling
                              ? AppLocalizations.of(context)!.installingStatus
                              : isAlreadyInstalled
                              ? AppLocalizations.of(context)!.alreadyInstalled
                              : AppLocalizations.of(context)!.installButton,
                          onPressed:
                              selectedInstance == null ||
                                  isInstalling ||
                                  isAlreadyInstalled
                              ? null
                              : _install,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
