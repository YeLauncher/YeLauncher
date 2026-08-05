import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class CoreCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final bool isSecondary;

  const CoreCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  }) : isSecondary = false;

  const CoreCheckbox.secondary({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  }) : isSecondary = true;

  @override
  State<CoreCheckbox> createState() => _CoreCheckboxState();
}

class _CoreCheckboxState extends State<CoreCheckbox> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isSecondary ? AppColors.dark.secondary : AppColors.dark.primary;
    final onActiveColor = widget.isSecondary ? AppColors.dark.onSecondary : AppColors.dark.onPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.value
                    ? activeColor
                    : _isHovered
                        ? AppColors.dark.onSurface.withValues(alpha: 0.1)
                        : const Color(0x00000000),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.value
                      ? activeColor
                      : AppColors.dark.onSurfaceVariant,
                  width: 2,
                ),
              ),
              child: widget.value
                  ? Icon(
                      Symbols.check_rounded,
                      size: 16,
                      color: onActiveColor,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.label,
                style: AppText.defaultTheme.labelLarge.copyWith(
                  color: widget.value ? AppColors.dark.onSurface : AppColors.dark.onSurfaceVariant,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

