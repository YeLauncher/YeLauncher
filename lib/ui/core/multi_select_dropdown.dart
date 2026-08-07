import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class MultiSelectDropdownItem<T> {
  final T value;
  final String label;

  const MultiSelectDropdownItem({required this.value, required this.label});
}

class MultiSelectDropdown<T> extends StatefulWidget {
  final List<T> values;
  final List<MultiSelectDropdownItem<T>> items;
  final ValueChanged<T> onToggle;
  final String emptyLabel;
  final IconData? iconData;

  const MultiSelectDropdown({
    super.key,
    required this.values,
    required this.items,
    required this.onToggle,
    required this.emptyLabel,
    this.iconData,
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isHovered = false;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isOpen) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDropdown,
              child: Container(constraints: const BoxConstraints.expand()),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: size.width + 60,
                  decoration: BoxDecoration(
                    color: AppColors.dark.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.scrim.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.dark.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widget.items.map((item) {
                            final isSelected = widget.values.contains(
                              item.value,
                            );
                            return _MultiSelectDropdownMenuItem(
                              item: item,
                              isSelected: isSelected,
                              onTap: () {
                                widget.onToggle(item.value);
                                // Don't close so they can select multiple
                                // We need to trigger rebuild of overlay to reflect new state
                                _overlayEntry?.markNeedsBuild();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  String _getLabel() {
    if (widget.values.isEmpty) return widget.emptyLabel;

    final selectedItems = widget.items
        .where((i) => widget.values.contains(i.value))
        .toList();
    if (selectedItems.isEmpty) return widget.emptyLabel;

    final firstLabel = selectedItems.first.label;
    if (selectedItems.length == 1) {
      return firstLabel;
    } else {
      return '$firstLabel +${selectedItems.length - 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.values.isNotEmpty
                  ? AppColors.dark.primaryContainer
                  : _isHovered || _isOpen
                  ? Color.alphaBlend(
                      AppColors.dark.onSurface.withValues(alpha: 0.08),
                      AppColors.dark.surfaceContainerHigh,
                    )
                  : AppColors.dark.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(milliseconds: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.iconData != null) ...[
                  Icon(
                    widget.iconData,
                    color: widget.values.isNotEmpty
                        ? AppColors.dark.onPrimaryContainer
                        : AppColors.dark.onSurface,
                    size: AppText.defaultTheme.labelLarge.fontSize,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _getLabel(),
                  style: AppText.defaultTheme.labelLarge.copyWith(
                    color: widget.values.isNotEmpty
                        ? AppColors.dark.onPrimaryContainer
                        : AppColors.dark.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isOpen
                      ? Symbols.arrow_drop_up_rounded
                      : Symbols.arrow_drop_down_rounded,
                  color: widget.values.isNotEmpty
                      ? AppColors.dark.onPrimaryContainer
                      : AppColors.dark.onSurfaceVariant,
                  size: AppText.defaultTheme.labelLarge.fontSize! + 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiSelectDropdownMenuItem<T> extends StatefulWidget {
  final MultiSelectDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiSelectDropdownMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MultiSelectDropdownMenuItem<T>> createState() =>
      _MultiSelectDropdownMenuItemState<T>();
}

class _MultiSelectDropdownMenuItemState<T>
    extends State<_MultiSelectDropdownMenuItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: widget.isSelected
              ? AppColors.dark.primary.withValues(alpha: 0.15)
              : _isHovered
              ? AppColors.dark.onSurface.withValues(alpha: 0.05)
              : const Color(0x00000000),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.label,
                  style: AppText.defaultTheme.bodyLarge.copyWith(
                    color: widget.isSelected
                        ? AppColors.dark.primary
                        : AppColors.dark.onSurface,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Symbols.check_rounded,
                  color: AppColors.dark.primary,
                  size: 18,
                )
              else
                Icon(
                  Symbols.check_box_outline_blank_rounded,
                  color: AppColors.dark.onSurfaceVariant,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
