import 'package:flutter/material.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

class NavigationButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isSelected;
  final IconData iconData;
  final Color selectedIconColor;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color iconColor;

  const NavigationButton({
    super.key,
    this.onPressed,
    required this.iconData,
    required this.backgroundColor,
    required this.iconColor,
    required this.selectedIconColor,
    required this.selectedBackgroundColor,
    required this.isSelected,
  });

  NavigationButton.primary({
    super.key,
    this.onPressed,
    required this.iconData,
    required this.isSelected
  }) : backgroundColor = AppColors.transparent,
       selectedBackgroundColor = AppColors.dark.inversePrimary,
       iconColor = AppColors.dark.onSurface,
       selectedIconColor = AppColors.dark.inverseOnPrimary;

  @override
  State<StatefulWidget> createState() => _IconButtonState();
}

class _IconButtonState extends State<NavigationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(milliseconds: 150),
          child: Icon(
            widget.iconData,
            color: widget.isSelected
                ? widget.selectedIconColor
                : widget.iconColor,
            fill: widget.isSelected ? 1 : 0,
            size: 24,
          ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (widget.isSelected) {
      return widget.selectedBackgroundColor;
    }
    if (_isHovered) {
      return Color.alphaBlend(
        widget.iconColor.withValues(alpha: 0.08),
        widget.backgroundColor,
      );
    }
    return widget.backgroundColor;
  }
}
