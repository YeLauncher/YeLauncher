import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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
import 'package:logging/logging.dart';

class ContentInstallDialog extends StatefulWidget {
  final ContentDetailViewModel viewModel;
  final ContentVersion? targetVersion;

  const ContentInstallDialog({
    super.key,
    required this.viewModel,
    this.targetVersion,
  });

  @override
  State<ContentInstallDialog> createState() => _ContentInstallDialogState();
}

class _ContentInstallDialogState extends State<ContentInstallDialog> {
  InstanceModel? selectedInstance;
  bool isInstalling = false;
  String? errorMessage;
  
  final _log = Logger('ContentInstallDialog');
  List<ResolvedDependency> resolvedDependencies = [];
  bool isResolvingDependencies = false;

  @override
  void initState() {
    super.initState();
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
                  (loaderLower == 'quilt' && v.loaders.contains('fabric')))) {
                depVersion = v;
                break;
              }
            }
          }
        }

        if (depVersion != null) {
          final itemRes = await repo.getContent(depVersion.projectId);
          if (itemRes is Success<ContentItem>) {
            resolved.add(ResolvedDependency(item: itemRes.value, version: depVersion));
            await resolve(depVersion);
          }
        }
      }
    }

    try {
      final vToResolve = widget.targetVersion ?? widget.viewModel.getBestVersionForInstance(instance);
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

  @override
  Widget build(BuildContext context) {
    final compatibleInstances = widget.targetVersion != null 
        ? widget.viewModel.getCompatibleInstances(widget.targetVersion!).toList()
        : widget.viewModel.instances.where((i) => widget.viewModel.getBestVersionForInstance(i) != null).toList();
        
    compatibleInstances.sort((a, b) {
      final vA = widget.targetVersion ?? widget.viewModel.getBestVersionForInstance(a)!;
      final aInstalled = a.installedContent.any((c) => c.projectId == widget.viewModel.item.id && c.versionId == vA.id);
      
      final vB = widget.targetVersion ?? widget.viewModel.getBestVersionForInstance(b)!;
      final bInstalled = b.installedContent.any((c) => c.projectId == widget.viewModel.item.id && c.versionId == vB.id);
      
      if (aInstalled == bInstalled) return a.name.compareTo(b.name);
      return aInstalled ? 1 : -1;
    });
    
    bool isAlreadyInstalled = false;
    ContentVersion? versionToInstall;
    if (selectedInstance != null) {
      versionToInstall = widget.targetVersion ?? widget.viewModel.getBestVersionForInstance(selectedInstance!);
      if (versionToInstall != null) {
        isAlreadyInstalled = selectedInstance!.installedContent.any(
          (content) => content.projectId == widget.viewModel.item.id && content.versionId == versionToInstall!.id
        );
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 600,
        maxHeight: 600,
      ),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.dark.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.selectInstance, style: AppText.defaultTheme.title.copyWith(color: AppColors.dark.onSurface)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Symbols.close_rounded, color: AppColors.dark.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (widget.viewModel.item.iconUrl?.isEmpty ?? true)
                        ? Icon(
                            Symbols.broken_image_rounded,
                            size: 48,
                            color: AppColors.dark.surfaceContainerHighest,
                          )
                        : CachedNetworkImage(
                            imageUrl: widget.viewModel.item.iconUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder: (context, url, downloadProgress) => Skeletonizer(
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
          Text(AppLocalizations.of(context)!.selectInstanceSubtitle, style: AppText.defaultTheme.bodySmall.copyWith(color: AppColors.dark.onSurface)),
          const SizedBox(height: 12),
          if (compatibleInstances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(AppLocalizations.of(context)!.noCompatibleInstances, style: AppText.defaultTheme.body.copyWith(color: AppColors.dark.onSurfaceVariant))),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: compatibleInstances.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final instance = compatibleInstances[index];
                  final isSelected = selectedInstance == instance;
                  
                  final vForInst = widget.targetVersion ?? widget.viewModel.getBestVersionForInstance(instance)!;
                  final isInstalled = instance.installedContent.any(
                    (content) => content.projectId == widget.viewModel.item.id && content.versionId == vForInst.id
                  );
                  
                  return Opacity(
                    opacity: isInstalled ? 0.5 : 1.0,
                    child: ListItem.secondary(
                      title: instance.name,
                      subtitle: '${instance.minecraftVersion} - ${instance.modLoader}',
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
          if (isResolvingDependencies)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator.primary(size: 16)),
                  const SizedBox(width: 8),
                  Text('Resolving dependencies...', style: AppText.defaultTheme.bodySmall.copyWith(color: AppColors.dark.onSurfaceVariant)),
                ],
              ),
            ),
          if (!isResolvingDependencies && resolvedDependencies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Required Dependencies (${resolvedDependencies.length}):', style: AppText.defaultTheme.titleSmall.copyWith(color: AppColors.dark.onSurface)),
                  const SizedBox(height: 4),
                  ...resolvedDependencies.map((dep) => Text(
                        '• ${dep.item.title} (${dep.version.versionNumber})',
                        style: AppText.defaultTheme.bodySmall.copyWith(color: AppColors.dark.onSurfaceVariant),
                      )),
                ],
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
                AppLocalizations.of(context)!.cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Button.primary(
                isInstalling 
                    ? AppLocalizations.of(context)!.installingStatus 
                    : isAlreadyInstalled 
                        ? AppLocalizations.of(context)!.alreadyInstalled 
                        : AppLocalizations.of(context)!.installButton,
                onPressed: selectedInstance == null || isInstalling || isAlreadyInstalled ? null : _install,
              ),
            ],
          ),
        ],
      ),
      ),
    );
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
      final currentInstance = allInstances.firstWhere((i) => i.id == selectedInstance!.id);
      
      final newInstalledContent = List<InstalledContentModel>.from(currentInstance.installedContent);

      Future<void> downloadAndInstall(ContentItem item, ContentVersion version) async {
        if (newInstalledContent.any((c) => c.projectId == item.id && c.versionId == version.id)) {
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
        
        file ??= version.files.firstWhere((f) => f.primary, orElse: () => version.files.first);
        
        final url = file.url;
        final fileName = Uri.decodeFull(file.filename);

        final folderName = switch (type) {
          'resourcepack' => 'resourcepacks',
          'shader' => 'shaderpacks',
          _ => 'mods',
        };
        final relativePath = 'instances/${selectedInstance!.id}/$folderName/$fileName';

        await downloadService.downloadIfMissing(
          DownloadModel(url: url, path: relativePath, sha1: ''),
        );

        // Remove existing installed content if present
        final existingIndex = newInstalledContent.indexWhere((c) => c.projectId == item.id);
        if (existingIndex != -1) {
          final oldContent = newInstalledContent[existingIndex];
          final appData = await getApplicationSupportDirectory();
          final oldFile = File(p.join(appData.path, 'instances', selectedInstance!.id, folderName, Uri.decodeFull(oldContent.filename)));
          
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
      final mainVersionToInstall = widget.targetVersion ?? widget.viewModel.getBestVersionForInstance(currentInstance);
      if (mainVersionToInstall == null) {
        throw Exception('No compatible version found for this instance.');
      }
      
      await downloadAndInstall(widget.viewModel.item, mainVersionToInstall);

      // Install all resolved dependencies
      for (final dep in resolvedDependencies) {
        await downloadAndInstall(dep.item, dep.version);
      }

      final updatedInstance = currentInstance.copyWith(installedContent: newInstalledContent);
      await instanceRepo.saveInstance(updatedInstance);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = AppLocalizations.of(context)!.errorWithParam(e.toString());
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
