import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class Chip extends StatelessWidget {
  final IconData? iconData;
  final String? svgIcon;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const Chip({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.iconData,
    this.svgIcon,
  });

  Chip.primary(this.text, {super.key, this.iconData, this.svgIcon})
    : backgroundColor = AppColors.dark.primaryContainer,
      textColor = AppColors.dark.onPrimaryContainer;

  Chip.secondary(this.text, {super.key, this.iconData, this.svgIcon})
    : backgroundColor = AppColors.dark.inverseSecondary,
      textColor = AppColors.dark.inverseOnSecondary;

  Chip.surface(this.text, {super.key, this.iconData, this.svgIcon})
    : backgroundColor = AppColors.dark.surfaceContainerHigh,
      textColor = AppColors.dark.onSurface;

  const Chip.tertiary(this.text, {super.key, this.iconData, this.svgIcon})
    : backgroundColor = const Color(0xFF2C4A6B),
      textColor = const Color(0xFFD4E8FC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        spacing: 6,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgIcon != null)
            SvgPicture.asset(
              svgIcon!,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            )
          else if (iconData != null)
            Icon(iconData, size: 14, color: textColor, weight: 600,),
          Flexible(
            child: Text(
              text,
              style: AppText.defaultTheme.labelLarge.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
