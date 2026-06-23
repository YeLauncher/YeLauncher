import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class Chip extends StatelessWidget {
  final IconData? iconData;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const Chip({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.iconData,
  });

  Chip.primary(this.text, {super.key, this.iconData})
    : backgroundColor = AppColors.dark.primaryContainer,
      textColor = AppColors.dark.onPrimaryContainer;

  Chip.secondary(this.text, {super.key, this.iconData})
    : backgroundColor = AppColors.dark.inverseSecondary,
      textColor = AppColors.dark.inverseOnSecondary;

  Chip.surface(this.text, {super.key, this.iconData})
    : backgroundColor = AppColors.dark.surfaceContainerHigh,
      textColor = AppColors.dark.onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[Icon(iconData, size: 14, color: textColor, weight: 600,)],
          Text(
            text,
            style: AppText.defaultTheme.label.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
