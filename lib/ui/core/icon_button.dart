import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

class IconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData iconData;
  final Color backgroundColor;
  final Color iconColor;

  const IconButton({
    super.key,
    this.onPressed,
    required this.iconData,
    required this.backgroundColor,
    required this.iconColor,
  });

  IconButton.surface({this.onPressed, required this.iconData, super.key})
    : backgroundColor = AppColors.dark.surfaceContainerHigh,
      iconColor = AppColors.dark.onSurface;

  IconButton.transparent({this.onPressed, required this.iconData, super.key})
    : backgroundColor = Color(0x00000000),
      iconColor = AppColors.dark.onSurface;

  @override
  State<StatefulWidget> createState() => _IconButtonState();
}

class _IconButtonState extends State<IconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(milliseconds: 150),
          child: Icon(
            widget.iconData,
            color: AppColors.dark.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (_isPressed) {
      return Color.alphaBlend(
        widget.iconColor.withValues(alpha: 0.12),
        widget.backgroundColor,
      );
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
