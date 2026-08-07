import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';
import 'package:yelauncher/ui/core/toast/toast_service.dart';

class ToastWidget extends StatefulWidget {
  final ToastMessage toast;
  final VoidCallback onDismiss;
  final bool isRemoving;

  const ToastWidget({
    super.key,
    required this.toast,
    required this.onDismiss,
    this.isRemoving = false,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isHovered = false;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.toast.duration,
    )..forward();

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!widget.isRemoving) {
      final remaining = widget.toast.duration * (1 - _progressController.value);
      _timer = Timer(remaining, widget.onDismiss);
      _progressController.forward();
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    _progressController.stop();
  }

  @override
  void didUpdateWidget(covariant ToastWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRemoving) {
      _pauseTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  Color _getAccentColor() {
    switch (widget.toast.type) {
      case ToastType.info:
        return AppColors.dark.outline;
      case ToastType.success:
        return AppColors.dark.primary;
      case ToastType.error:
        return AppColors.dark.error;
    }
  }

  IconData _getIcon() {
    switch (widget.toast.type) {
      case ToastType.info:
        return Symbols.info_rounded;
      case ToastType.success:
        return Symbols.check_circle_rounded;
      case ToastType.error:
        return Symbols.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _pauseTimer();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _startTimer();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dark.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent line
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_getIcon(), color: accentColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.toast.title,
                                  style: AppText.defaultTheme.labelLarge
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dark.onSurface,
                                      ),
                                ),
                                if (widget.toast.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.toast.description!,
                                    style: AppText.defaultTheme.bodyMedium
                                        .copyWith(
                                          color:
                                              AppColors.dark.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? AppColors.dark.surfaceContainerHigh
                                    : const Color(0x00000000),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Symbols.close_rounded,
                                color: AppColors.dark.onSurfaceVariant,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
