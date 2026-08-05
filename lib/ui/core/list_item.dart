import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

import 'chip.dart';

class ListItem extends StatefulWidget {
  const ListItem({
    super.key,
    required this.title,
    this.trailingIcon,
    this.trailingWidget,
    this.isSelected = false,
    this.onTap,
    required this.selectedColor,
    this.selectedBackgroundColor,
    this.chip,
    this.subtitle,
    this.leadingWidget,
    this.tags,
  });

  final String title;
  final String? subtitle;
  final Chip? chip;
  final IconData? trailingIcon;
  final Widget? trailingWidget;
  final Widget? leadingWidget;
  final List<Widget>? tags;
  final Color selectedColor;
  final Color? selectedBackgroundColor;
  final bool isSelected;
  final VoidCallback? onTap;

  ListItem.primary({
    this.subtitle,
    required this.title,
    this.chip,
    this.trailingIcon,
    this.trailingWidget,
    this.leadingWidget,
    this.tags,
    required this.isSelected,
    this.onTap,
    super.key,
  }) : selectedColor = AppColors.dark.primary,
       selectedBackgroundColor = AppColors.dark.primaryContainer;

  ListItem.secondary({
    this.subtitle,
    required this.title,
    this.chip,
    this.trailingIcon,
    this.trailingWidget,
    this.leadingWidget,
    this.tags,
    required this.isSelected,
    this.onTap,
    super.key,
  }) : selectedColor = AppColors.dark.secondary,
       selectedBackgroundColor = null;

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (widget.selectedBackgroundColor ??
                      widget.selectedColor.withValues(alpha: 0.1))
                : _isHovered
                ? AppColors.dark.surfaceContainerHighest
                : AppColors.dark.surfaceContainerHigh,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              width: 1.5,
              color: widget.isSelected
                  ? widget.selectedColor
                  : AppColors.dark.outlineVariant.withValues(
                      alpha: _isHovered ? 1.0 : 0.0,
                    ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (widget.leadingWidget != null) ...[
                widget.leadingWidget!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.defaultTheme.labelLarge.copyWith(
                        color: widget.isSelected
                            ? widget.selectedColor
                            : AppColors.dark.onSurface,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.defaultTheme.labelSmall.copyWith(
                          color: AppColors.dark.onSurfaceVariant,
                        ),
                      ),
                    if (widget.tags != null && widget.tags!.isNotEmpty)
                      Wrap(spacing: 8, runSpacing: 8, children: widget.tags!),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (widget.chip != null) ...[
                widget.chip!,
                if (widget.trailingWidget != null ||
                    (widget.trailingIcon != null && widget.isSelected))
                  const SizedBox(width: 16),
              ],
              if (widget.trailingIcon != null && widget.isSelected) ...[
                Icon(
                  widget.trailingIcon,
                  size: 24,
                  color: widget.selectedColor,
                  weight: 600,
                ),
                if (widget.trailingWidget != null) const SizedBox(width: 16),
              ],
              if (widget.trailingWidget != null) widget.trailingWidget!,
            ],
          ),
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
