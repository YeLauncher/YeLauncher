import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:yelauncher/ui/core/toast/toast_service.dart';
import 'package:yelauncher/ui/core/toast/toast_widget.dart';

class ToastOverlay extends StatefulWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  final List<ToastMessage> _toasts = [];
  final List<String> _removingIds = [];
  StreamSubscription? _subscription;
  bool _isHovered = false;

  static const int _maxVisibleToasts = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final toastService = context.read<ToastService>();
      _subscription = toastService.onToast.listen(_handleNewToast);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleNewToast(ToastMessage toast) {
    setState(() {
      _toasts.insert(0, toast);
    });
  }

  void _removeToast(String id) {
    setState(() {
      if (!_removingIds.contains(id)) {
        _removingIds.add(id);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _toasts.removeWhere((t) => t.id == id);
          _removingIds.remove(id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 24.0,
          right: 24.0,
          width: 320.0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: _buildToastStack(),
          ),
        ),
      ],
    );
  }

  Widget _buildToastStack() {
    if (_toasts.isEmpty && _removingIds.isEmpty) return const SizedBox();

    final activeToasts = _toasts.take(_maxVisibleToasts + _removingIds.length).toList();
    final reversedToasts = activeToasts.reversed.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: reversedToasts.asMap().entries.map((entry) {
        final toast = entry.value;
        final isRemoving = _removingIds.contains(toast.id);
        
        // Ensure indexFromNewest respects only active non-removing toasts if possible, 
        // but for simplicity we just base it on indexOf
        final int indexFromNewest = activeToasts.indexOf(toast);
        final bool isTooOld = !isRemoving && indexFromNewest >= _maxVisibleToasts;
        
        final double heightFactor = indexFromNewest == 0 
            ? 1.0 
            : (_isHovered ? 1.05 : 0.25);
            
        final double scale = _isHovered 
            ? 1.0 
            : 1.0 - (indexFromNewest * 0.05).clamp(0.0, 1.0);
            
        final double opacity = isRemoving || isTooOld 
            ? 0.0 
            : 1.0 - (indexFromNewest * 0.2).clamp(0.0, 1.0);

        final double horizontalOffset = isRemoving ? 320.0 : 0.0;

        return TweenAnimationBuilder<double>(
          key: ValueKey(toast.id),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: heightFactor, end: heightFactor),
          builder: (context, value, child) {
            return Align(
              alignment: Alignment.topCenter,
              heightFactor: value,
              child: child,
            );
          },
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(horizontalOffset, 0, 0),
                child: IgnorePointer(
                  ignoring: isRemoving || opacity == 0.0,
                  child: ToastWidget(
                    toast: toast,
                    onDismiss: () => _removeToast(toast.id),
                    isRemoving: isRemoving,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
