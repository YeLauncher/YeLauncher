import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:yelauncher/domain/models/content/content_item.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class ContentCard extends StatefulWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const ContentCard({super.key, required this.item, required this.onTap});

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _isHovered = false;

  String _formatDownloads(int? downloads) {
    if (downloads == null) return '0';
    return NumberFormat.compact().format(downloads);
  }

  String _formatGameVersions() {
    final versions = widget.item.gameVersions;
    if (versions == null || versions.isEmpty) return '';
    final releasePattern = RegExp(r'^\d+\.\d+(?:\.\d+)?$');
    final releases = versions.where((v) => releasePattern.hasMatch(v)).toList();
    if (releases.isEmpty) return '';
    if (releases.length == 1) return releases.first;
    return '${releases.first}-${releases.last}';
  }

  List<String> _getValidLoaders() {
    final loaders = widget.item.loaders ?? [];
    return loaders
        .map((l) => l.toLowerCase())
        .where((l) => l == 'fabric' || l == 'forge' || l == 'neoforge')
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color cardBackground = AppColors.dark.surfaceContainer;
    final Color hoverColor = AppColors.dark.surfaceContainerHigh;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(maxWidth: 500, minHeight: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppColors.dark.outline
                  : AppColors.transparent,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              // Top Row: Main Icon and Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Hero(
                    tag: 'content_icon_${widget.item.id}',
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.item.iconUrl?.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: widget.item.iconUrl!,
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) =>
                                        Skeletonizer(
                                          enabled: true,
                                          containersColor: AppColors
                                              .dark
                                              .surfaceContainerHigh,
                                          effect: ShimmerEffect(
                                            baseColor: AppColors
                                                .dark
                                                .surfaceContainerHighest,
                                            highlightColor: AppColors
                                                .dark
                                                .surfaceContainerHighest,
                                          ),
                                          child: Container(
                                            width: 64,
                                            height: 64,
                                            color: AppColors
                                                .dark
                                                .surfaceContainerHighest,
                                          ),
                                        ),
                                errorWidget: (context, url, error) => Icon(
                                  Symbols.broken_image_rounded,
                                  size: 48,
                                  color: AppColors.dark.surfaceContainerHighest,
                                ),
                              )
                            : Container(
                                color: AppColors.dark.surfaceContainerHighest,
                                child: Icon(
                                  Symbols.extension,
                                  size: 32,
                                  color: AppColors.dark.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.title,
                          style: AppText.defaultTheme.titleLarge.copyWith(
                            color: AppColors.dark.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (widget.item.author != null ||
                            widget.item.organization != null ||
                            widget.item.teamId != null)
                          Text(
                            AppLocalizations.of(context)!.byAuthor(
                              widget.item.author ??
                                  widget.item.organization ??
                                  widget.item.teamId ??
                                  '',
                            ),
                            style: AppText.defaultTheme.labelSmall.copyWith(
                              color: AppColors.dark.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description Text
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  widget.item.description,
                  style: AppText.defaultTheme.bodyMedium.copyWith(
                    color: AppColors.dark.onSurfaceVariant,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Bottom Metadata Row
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        Symbols.download,
                        size: 16,
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                      Text(
                        _formatDownloads(widget.item.downloads),
                        style: AppText.defaultTheme.labelLarge.copyWith(
                          color: AppColors.dark.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (_formatGameVersions().isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(
                          Symbols.gamepad,
                          size: 16,
                          color: AppColors.dark.onSurfaceVariant,
                        ),
                        Text(
                          _formatGameVersions(),
                          style: AppText.defaultTheme.labelLarge.copyWith(
                            color: AppColors.dark.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  if (_getValidLoaders().isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: _getValidLoaders()
                          .map(
                            (loader) => loader == 'fabric'
                                ? Assets.fabricLogo
                                : Assets.forgeLogo,
                          )
                          .toSet()
                          .map((assetPath) {
                            return SvgPicture.asset(
                              assetPath,
                              height: assetPath == Assets.fabricLogo ? 16 : 14,
                            );
                          })
                          .toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
