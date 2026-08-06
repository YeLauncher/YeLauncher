import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/core/breadcrumb_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yelauncher/config/assets.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/core/notification_provider.dart';
import 'package:yelauncher/ui/core/notification_popup.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;
  final OverlayPortalController _notificationPortalController = OverlayPortalController();
  final LayerLink _notificationLayerLink = LayerLink();

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

          // Notification Bell
          CompositedTransformTarget(
            link: _notificationLayerLink,
            child: OverlayPortal(
              controller: _notificationPortalController,
              overlayChildBuilder: (context) {
                return Stack(
                  children: [
                    // Invisible barrier to close popup when tapping outside
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _notificationPortalController.hide(),
                        child: Container(color: const Color(0x00000000)),
                      ),
                    ),
                    Positioned(
                      top: 48, // Height of the title bar
                      right: 138, // Before window controls
                      child: CompositedTransformFollower(
                        link: _notificationLayerLink,
                        showWhenUnlinked: false,
                        offset: const Offset(-280, 48), // Align right, below the bell
                        child: const NotificationPopup(),
                      ),
                    ),
                  ],
                );
              },
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final activeCount = notificationProvider.activeCount;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _WindowButton(
                        icon: Symbols.notifications_rounded,
                        onPressed: () => _notificationPortalController.toggle(),
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.dark.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
