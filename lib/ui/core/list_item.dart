import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.title,
    this.badgeText,
    this.badgeColor,
    this.badgeBackgroundColor,
    this.trailingText,
    this.isSelected = false,
    this.onTap,
  });

  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBackgroundColor;
  final String? trailingText;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dark.surfaceContainerHigh,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            width: 2,
            color: isSelected ? AppColors.dark.primary : AppColors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: AppText.defaultTheme.labelLarge.copyWith(
                color: AppColors.dark.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      badgeBackgroundColor ?? AppColors.dark.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText!,
                  style: AppText.defaultTheme.caption.copyWith(
                    color: badgeColor ?? AppColors.dark.onPrimaryContainer,
                  ),
                ),
              ),
            const Spacer(),
            if (trailingText != null)
              Text(
                trailingText!,
                style: AppText.defaultTheme.bodySmall.copyWith(
                  color: AppColors.dark.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
