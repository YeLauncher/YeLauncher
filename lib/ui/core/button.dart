import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class Button extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? iconData;

  const Button({
    super.key,
    this.onPressed,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.iconData,
  });

  Button.primary(this.label, {this.onPressed, super.key, this.iconData})
    : backgroundColor = AppColors.dark.primary,
      textColor = AppColors.dark.onPrimary;

  Button.secondary(this.label, {this.onPressed, super.key, this.iconData})
    : backgroundColor = AppColors.dark.secondary,
      textColor = AppColors.dark.onSecondary;

  Button.surface(this.label, {this.onPressed, super.key, this.iconData})
    : backgroundColor = AppColors.dark.surfaceContainerHigh,
      textColor = AppColors.dark.onSurface;

  Button.error(this.label, {this.onPressed, super.key, this.iconData})
    : backgroundColor = AppColors.dark.error,
      textColor = AppColors.dark.scrim;

  @override
  State<StatefulWidget> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
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
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(milliseconds: 150),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.iconData != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        widget.iconData,
                        color: widget.textColor,
                        size: AppText.defaultTheme.label.fontSize,
                        weight: 600,
                      ),
                    )
                  : const SizedBox.shrink(),
              Text(
                widget.label,
                style: AppText.defaultTheme.label.copyWith(
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (_isPressed) {
      return Color.alphaBlend(
        widget.textColor.withValues(alpha: 0.12),
        widget.backgroundColor,
      );
    }
    if (_isHovered) {
      return Color.alphaBlend(
        widget.textColor.withValues(alpha: 0.08),
        widget.backgroundColor,
      );
    }
    return widget.backgroundColor;
  }
}
