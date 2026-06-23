import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int maxWidth;
  final int maxHeight;
  final int minWidth;
  final int minHeight;
  final String description;
  final List<Widget> buttons;

  const Card({
    super.key,
    required this.title,
    required this.description,
    required this.buttons,
    this.imageUrl,
    this.subtitle,
    required this.maxWidth,
    required this.maxHeight,
    required this.minWidth,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 500, maxHeight: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dark.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          // Top Row: Main Icon, Title, and Info Icon Button
          Row(
            spacing: 12,
            children: [
              // Main Icon (Represented via an Emoji / Unicode Character)
              SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? "",
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Skeletonizer(
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
              ),

              // Title
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      title,
                      style: AppText.defaultTheme.titleSmall.copyWith(
                        color: AppColors.dark.onSurface,
                      ),
                    ),
                    Text(
                      subtitle ?? "",
                      style: AppText.defaultTheme.caption.copyWith(
                        color: AppColors.dark.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description Text
          Text(
            description,
            style: AppText.defaultTheme.bodySmall.copyWith(
              color: AppColors.dark.onSurface,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),

          // Add Button
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: buttons,
          ),
        ],
      ),
    );
  }
}

@Preview(name: "Card test")
Widget card() {
  return const Card(
    title: "Sodium",
    subtitle: "by CaffeineMC",
    imageUrl:
        "https://cdn.modrinth.com/data/AANobbMI/295862f4724dc3f78df3447ad6072b2dcd3ef0c9_96.webp",
    description:
        "A high-performance rendering engine replacement for Minecraft, which greatly improves frame rates and reduces micro-stutter.",
    buttons: [],
    maxWidth: 300,
    maxHeight: 300,
    minWidth: 300,
    minHeight: 300,
  );
}
