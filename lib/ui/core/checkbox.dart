import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class CoreCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const CoreCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  State<CoreCheckbox> createState() => _CoreCheckboxState();
}

class _CoreCheckboxState extends State<CoreCheckbox> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
                    ? AppColors.dark.primary
                    : _isHovered
                        ? AppColors.dark.onSurface.withValues(alpha: 0.1)
                        : const Color(0x00000000),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.value
                      ? AppColors.dark.primary
                      : AppColors.dark.onSurfaceVariant,
                  width: 2,
                ),
              ),
              child: widget.value
                  ? Icon(
                      Symbols.check_rounded,
                      size: 16,
                      color: AppColors.dark.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: AppText.defaultTheme.label.copyWith(
                color: widget.value ? AppColors.dark.onSurface : AppColors.dark.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
