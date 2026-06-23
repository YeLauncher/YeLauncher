import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

import 'chip.dart';

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.title,
    this.trailingIcon,
    this.isSelected = false,
    this.onTap,
    required this.selectedColor,
    this.chip,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Chip? chip;
  final IconData? trailingIcon;
  final Color selectedColor;
  final bool isSelected;
  final VoidCallback? onTap;

  ListItem.primary({
    this.subtitle,
    required this.title,
    this.chip,
    this.trailingIcon,
    required this.isSelected,
    this.onTap,
    super.key,
  }) : selectedColor = AppColors.dark.primary;

  ListItem.secondary({
    this.subtitle,
    required this.title,
    this.chip,
    this.trailingIcon,
    required this.isSelected,
    this.onTap,
    super.key,
  }) : selectedColor = AppColors.dark.secondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dark.surfaceContainerHigh,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            width: 2,
            color: isSelected ? selectedColor : AppColors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  title,
                  style: AppText.defaultTheme.labelLarge.copyWith(
                    color: AppColors.dark.onSurface,
                  ),
                ),
                if (subtitle != null) Text(
                  subtitle!,
                  style: AppText.defaultTheme.caption.copyWith(
                    color: AppColors.dark.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            ?chip,
            const Spacer(),
            if (trailingIcon != null && isSelected)
              Icon(trailingIcon, size: 24, color: selectedColor, weight: 600),
          ],
        ),
      ),
    );
  }
}

// 1. Default Unselected
@Preview(name: "Primary - Unselected")
Widget primaryUnselectedListItemPreview() {
  return ListItem.primary(title: "Standard Item", isSelected: false);
}

// 2. Primary Selected with Icon
@Preview(name: "Primary - Selected")
Widget primarySelectedListItemPreview() {
  return ListItem.primary(
    title: "Selected Item",
    isSelected: true,
    trailingIcon: Symbols.check_circle_rounded,
  );
}

// 3. Secondary Selected with Icon
@Preview(name: "Secondary - Selected")
Widget secondarySelectedListItemPreview() {
  return ListItem.secondary(
    title: "Secondary Selected",
    isSelected: true,
    trailingIcon: Symbols.star_rounded,
  );
}

// 4. With Subtitle
@Preview(name: "With Subtitle")
Widget withSubtitleListItemPreview() {
  return ListItem.primary(
    title: "Main Title",
    subtitle: "This is a descriptive subtitle",
    isSelected: false,
  );
}

// 5. With Primary Chip
@Preview(name: "With Primary Chip")
Widget withPrimaryChipListItemPreview() {
  return ListItem.primary(
    title: "Update Available",
    chip: Chip.primary("New"),
    isSelected: false,
  );
}

// 6. With Secondary Chip
@Preview(name: "With Secondary Chip")
Widget withSecondaryChipListItemPreview() {
  return ListItem.secondary(
    title: "Beta Feature",
    chip: Chip.secondary("Beta"),
    isSelected: false,
  );
}

// 7. Complex (All Elements Combined)
@Preview(name: "Complex - All Elements")
Widget complexListItemPreview() {
  return ListItem.primary(
    title: "Pro Subscription",
    subtitle: "Renews on Jan 1st",
    chip: Chip.primary("Pro"),
    trailingIcon: Symbols.arrow_forward_ios_rounded,
    isSelected: true,
  );
}
