import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/core/breadcrumb_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yelauncher/config/assets.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.dark.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Area + Drag Handle
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SvgPicture.asset(Assets.logo, height: 20, width: 20),
                  const SizedBox(width: 8),
                  Text(
                    'YeLauncher',
                    style: AppText.defaultTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark.onSurface,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Breadcrumbs integrated into the drag area
                  const BreadcrumbBar(),
                ],
              ),
            ),
          ),

          // Window Controls
          _WindowButton(
            icon: Symbols.minimize_rounded,
            onPressed: () => windowManager.minimize(),
          ),
          _WindowButton(
            icon: _isMaximized
                ? Symbols.filter_none_rounded
                : Symbols.crop_square_rounded,
            onPressed: () {
              if (_isMaximized) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _WindowButton(
            icon: Symbols.close_rounded,
            isClose: true,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0x00000000);
    if (_isHovered) {
      bgColor = widget.isClose
          ? const Color(0xFFE81123)
          : AppColors.dark.surfaceContainerHigh;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
          width: 46, // Standard Windows button width
          color: bgColor,
          child: Center(
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered && widget.isClose
                  ? const Color(0xFFFFFFFF)
                  : AppColors.dark.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
