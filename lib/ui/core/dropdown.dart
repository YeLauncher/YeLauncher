import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class DropdownItem<T> {
  final T value;
  final String label;

  const DropdownItem({required this.value, required this.label});
}

class Dropdown<T> extends StatefulWidget {
  final T value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final IconData? iconData;

  const Dropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.iconData,
  });

  @override
  State<Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<Dropdown<T>> {
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
              child: Container(
                constraints: const BoxConstraints.expand(),
              ),
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
                      color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
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
                            final isSelected = item.value == widget.value;
                            return _DropdownMenuItem(
                              item: item,
                              isSelected: isSelected,
                              onTap: () {
                                widget.onChanged(item.value);
                                _closeDropdown();
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

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.first,
    );

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
              color: _isHovered || _isOpen
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
                    color: AppColors.dark.onSurface,
                    size: AppText.defaultTheme.label.fontSize,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  currentItem.label,
                  style: AppText.defaultTheme.label.copyWith(
                    color: AppColors.dark.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isOpen ? Symbols.arrow_drop_up_rounded : Symbols.arrow_drop_down_rounded,
                  color: AppColors.dark.onSurfaceVariant,
                  size: AppText.defaultTheme.label.fontSize! + 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuItem<T> extends StatefulWidget {
  final DropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DropdownMenuItem<T>> createState() => _DropdownMenuItemState<T>();
}

class _DropdownMenuItemState<T> extends State<_DropdownMenuItem<T>> {
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
                  style: AppText.defaultTheme.body.copyWith(
                    color: widget.isSelected
                        ? AppColors.dark.primary
                        : AppColors.dark.onSurface,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Symbols.check_rounded,
                  color: AppColors.dark.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
