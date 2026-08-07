import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/routing/breadcrumb_service.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:material_symbols_icons/symbols.dart';

class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({super.key});

  String? _getStaticTitle(BuildContext context, String segment) {
    final l10n = AppLocalizations.of(context)!;
    switch (segment) {
      case 'content':
        return l10n.contentTab;
      case 'instances':
        return l10n.instancesTab;
      case 'profiles':
        return l10n.profilesTabTitle;
      case 'settings':
        return l10n.settingsTabTitle;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return ValueListenableBuilder(
      valueListenable: router.routeInformationProvider,
      builder: (context, routeInfo, _) {
        final uri = Uri.parse(routeInfo.uri.toString());
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

        if (segments.isEmpty) return const SizedBox.shrink();

        return Consumer<BreadcrumbService>(
          builder: (context, breadcrumbService, _) {
            final children = <Widget>[];

            for (int i = 0; i < segments.length; i++) {
              final segment = segments[i];
              final isLast = i == segments.length - 1;

              String? title = _getStaticTitle(context, segment);
              bool isLoading = false;

              if (title == null) {
                title = breadcrumbService.getTitle(segment);
                if (title == null) {
                  title = 'Loading...';
                  isLoading = true;
                }
              }

              final Widget textWidget = Text(
                title,
                style: AppText.defaultTheme.titleMedium.copyWith(
                  color: isLast ? AppColors.dark.onSurface : AppColors.dark.onSurfaceVariant,
                  fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                ),
              );

              Widget itemWidget = isLoading
                  ? Skeletonizer(
                      enabled: true,
                      containersColor: AppColors.dark.skeletonContainer,
                      effect: ShimmerEffect(
                        baseColor: AppColors.dark.skeletonBase,
                        highlightColor: AppColors.dark.skeletonHighlight,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: AppColors.dark.skeletonBase,
                        child: textWidget,
                      ),
                    )
                  : textWidget;

              if (!isLast && !isLoading) {
                final pathTarget = '/${segments.sublist(0, i + 1).join('/')}';
                itemWidget = MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go(pathTarget),
                    child: itemWidget,
                  ),
                );
              }

              children.add(itemWidget);

              if (!isLast) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Symbols.chevron_right_rounded,
                      size: 16,
                      color: AppColors.dark.onSurfaceVariant,
                    ),
                  ),
                );
              }
            }

            return Row(
              children: children,
            );
          },
        );
      },
    );
  }
}
