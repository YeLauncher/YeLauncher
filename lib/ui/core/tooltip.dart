import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

const AnimationStyle _kDefaultAnimationStyle = AnimationStyle(
  curve: Curves.fastOutSlowIn,
  duration: Duration(milliseconds: 150),
  reverseDuration: Duration(milliseconds: 75),
);

typedef TooltipComponentBuilder =
    Widget Function(BuildContext context, Animation<double> animation);
typedef TooltipPositionDelegate =
    Offset Function(TooltipPositionContext context);

@immutable
class TooltipPositionContext {
  const TooltipPositionContext({
    required this.target,
    required this.targetSize,
    required this.tooltipSize,
    required this.verticalOffset,
    this.preferBelow = true,
    this.overlaySize = Size.infinite,
  });

  final Offset target;
  final Size targetSize;
  final Size tooltipSize;
  final double verticalOffset;
  final bool preferBelow;
  final Size overlaySize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TooltipPositionContext &&
        other.target == target &&
        other.targetSize == targetSize &&
        other.tooltipSize == tooltipSize &&
        other.overlaySize == overlaySize &&
        other.verticalOffset == verticalOffset &&
        other.preferBelow == preferBelow;
  }

  @override
  int get hashCode => Object.hash(
    target,
    targetSize,
    tooltipSize,
    overlaySize,
    verticalOffset,
    preferBelow,
  );
}

enum TooltipTriggerMode { manual, longPress, tap }

typedef TooltipTriggeredCallback = VoidCallback;

class _ExclusiveMouseRegion extends MouseRegion {
  const _ExclusiveMouseRegion({super.onEnter, super.onExit, super.child});
  @override
  _RenderExclusiveMouseRegion createRenderObject(BuildContext context) {
    return _RenderExclusiveMouseRegion(onEnter: onEnter, onExit: onExit);
  }
}

class _RenderExclusiveMouseRegion extends RenderMouseRegion {
  _RenderExclusiveMouseRegion({super.onEnter, super.onExit});
  static bool isOutermostMouseRegion = true;
  static bool foundInnermostMouseRegion = false;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    var isHit = false;
    final bool outermost = isOutermostMouseRegion;
    isOutermostMouseRegion = false;
    if (size.contains(position)) {
      isHit =
          hitTestChildren(result, position: position) || hitTestSelf(position);
      if ((isHit || behavior == HitTestBehavior.translucent) &&
          !foundInnermostMouseRegion) {
        foundInnermostMouseRegion = true;
        result.add(BoxHitTestEntry(this, position));
      }
    }
    if (outermost) {
      isOutermostMouseRegion = true;
      foundInnermostMouseRegion = false;
    }
    return isHit;
  }
}

class RawTooltip extends StatefulWidget {
  const RawTooltip({
    super.key,
    required this.semanticsTooltip,
    required this.tooltipBuilder,
    this.hoverDelay = Duration.zero,
    this.touchDelay = const Duration(milliseconds: 1500),
    this.dismissDelay = const Duration(milliseconds: 100),
    this.enableTapToDismiss = true,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.enableFeedback = true,
    this.onTriggered,
    this.animationStyle = _kDefaultAnimationStyle,
    this.positionDelegate,
    this.ignorePointer = false,
    required this.child,
  });

  final String? semanticsTooltip;
  final TooltipComponentBuilder tooltipBuilder;
  final Duration hoverDelay;
  final Duration touchDelay;
  final Duration dismissDelay;
  final bool enableTapToDismiss;
  final TooltipTriggerMode triggerMode;
  final bool enableFeedback;
  final TooltipTriggeredCallback? onTriggered;
  final AnimationStyle animationStyle;
  final TooltipPositionDelegate? positionDelegate;
  final bool ignorePointer;
  final Widget child;

  static final List<RawTooltipState> _openedTooltips = <RawTooltipState>[];

  static bool dismissAllToolTips() {
    if (_openedTooltips.isEmpty) return false;
    final List<RawTooltipState> openedTooltips = _openedTooltips.toList();
    for (final state in openedTooltips) {
      assert(state.mounted);
      state._scheduleDismissTooltip();
    }
    return true;
  }

  @override
  State<RawTooltip> createState() => RawTooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty(
        'semantics',
        semanticsTooltip,
        showName: semanticsTooltip == null || semanticsTooltip!.isEmpty,
        defaultValue: semanticsTooltip == null || semanticsTooltip!.isEmpty
            ? null
            : kNoDefaultValue,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration>(
        'hover delay',
        hoverDelay,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration>(
        'touch delay',
        touchDelay,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration>(
        'dismiss delay',
        dismissDelay,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<TooltipTriggerMode>(
        'triggerMode',
        triggerMode,
        defaultValue: null,
      ),
    );
    properties.add(
      FlagProperty(
        'enableFeedback',
        value: enableFeedback,
        ifTrue: 'true',
        showName: true,
      ),
    );
    properties.add(
      DiagnosticsProperty<TooltipPositionDelegate>(
        'positionDelegate',
        positionDelegate,
        defaultValue: null,
      ),
    );
  }
}

class RawTooltipState extends State<RawTooltip>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();

  Timer? _timer;
  AnimationController? _backingController;
  AnimationController get _controller {
    return _backingController ??= AnimationController(
      duration: widget.animationStyle.duration,
      reverseDuration: widget.animationStyle.reverseDuration,
      vsync: this,
    )..addStatusListener(_handleStatusChanged);
  }

  CurvedAnimation? _backingOverlayAnimation;
  CurvedAnimation get _overlayAnimation {
    return _backingOverlayAnimation ??= CurvedAnimation(
      parent: _controller,
      curve: widget.animationStyle.curve ?? _kDefaultAnimationStyle.curve!,
    );
  }

  LongPressGestureRecognizer? _longPressRecognizer;
  TapGestureRecognizer? _tapRecognizer;
  final Set<int> _activeHoveringPointerDevices = <int>{};
  AnimationStatus _animationStatus = AnimationStatus.dismissed;

  void _handleStatusChanged(AnimationStatus status) {
    assert(mounted);
    switch ((_animationStatus.isDismissed, status.isDismissed)) {
      case (false, true):
        RawTooltip._openedTooltips.remove(this);
        _overlayController.hide();
      case (true, false):
        _overlayController.show();
        RawTooltip._openedTooltips.add(this);
        SemanticsService.tooltip(widget.semanticsTooltip ?? '');
      case (true, true) || (false, false):
        break;
    }
    _animationStatus = status;
  }

  void _scheduleShowTooltip({
    required Duration withDelay,
    Duration? touchDelay,
  }) {
    assert(mounted);
    void show() {
      assert(mounted);
      _controller.forward();
      _timer?.cancel();
      _timer = touchDelay == null
          ? null
          : Timer(touchDelay, _controller.reverse);
    }

    assert(
      !(_timer?.isActive ?? false) ||
          _controller.status != AnimationStatus.reverse,
    );
    if (_controller.isDismissed && withDelay.inMicroseconds > 0) {
      _timer?.cancel();
      _timer = Timer(withDelay, show);
    } else {
      show();
    }
  }

  void _scheduleDismissTooltip({Duration withDelay = Duration.zero}) {
    assert(mounted);
    assert(
      !(_timer?.isActive ?? false) ||
          _backingController?.status != AnimationStatus.reverse,
    );
    _timer?.cancel();
    _timer = null;
    if (_backingController?.isForwardOrCompleted ?? false) {
      if (withDelay.inMicroseconds > 0) {
        _timer = Timer(withDelay, _controller.reverse);
      } else {
        _controller.reverse();
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    const triggerModeDeviceKinds = <PointerDeviceKind>{
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.stylus,
      PointerDeviceKind.touch,
      PointerDeviceKind.unknown,
      PointerDeviceKind.trackpad,
    };
    switch (widget.triggerMode) {
      case TooltipTriggerMode.longPress:
        final LongPressGestureRecognizer recognizer = _longPressRecognizer ??=
            LongPressGestureRecognizer(
              debugOwner: this,
              supportedDevices: triggerModeDeviceKinds,
            );
        recognizer
          ..onLongPressCancel = _handleTapToDismiss
          ..onLongPress = _handleLongPress
          ..onLongPressUp = _handlePressUp
          ..addPointer(event);
      case TooltipTriggerMode.tap:
        final TapGestureRecognizer recognizer = _tapRecognizer ??=
            TapGestureRecognizer(
              debugOwner: this,
              supportedDevices: triggerModeDeviceKinds,
            );
        recognizer
          ..onTapCancel = _handleTapToDismiss
          ..onTap = _handleTap
          ..addPointer(event);
      case TooltipTriggerMode.manual:
        break;
    }
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    assert(mounted);
    if (_tapRecognizer?.primaryPointer == event.pointer ||
        _longPressRecognizer?.primaryPointer == event.pointer) {
      return;
    }
    if ((_timer == null && _controller.isDismissed) ||
        event is! PointerDownEvent) {
      return;
    }
    _handleTapToDismiss();
  }

  void _handleTapToDismiss() {
    if (!widget.enableTapToDismiss) return;
    _scheduleDismissTooltip();
    _activeHoveringPointerDevices.clear();
  }

  void _handleTap() {
    final bool tooltipCreated = _controller.isDismissed;
    if (tooltipCreated && widget.enableFeedback) Feedback.forTap(context);
    widget.onTriggered?.call();
    _scheduleShowTooltip(
      withDelay: Duration.zero,
      touchDelay: _activeHoveringPointerDevices.isEmpty
          ? widget.touchDelay
          : null,
    );
  }

  void _handleLongPress() {
    final bool tooltipCreated = _controller.isDismissed;
    if (tooltipCreated && widget.enableFeedback) Feedback.forLongPress(context);
    widget.onTriggered?.call();
    _scheduleShowTooltip(withDelay: Duration.zero);
  }

  void _handlePressUp() {
    if (_activeHoveringPointerDevices.isNotEmpty) return;
    _scheduleDismissTooltip(withDelay: widget.touchDelay);
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    _activeHoveringPointerDevices.add(event.device);
    final List<RawTooltipState> tooltipsToDismiss = RawTooltip._openedTooltips
        .where(
          (RawTooltipState tooltip) =>
              tooltip._activeHoveringPointerDevices.isEmpty,
        )
        .toList();
    for (final tooltip in tooltipsToDismiss) {
      assert(tooltip.mounted);
      tooltip._scheduleDismissTooltip();
    }
    _scheduleShowTooltip(
      withDelay: tooltipsToDismiss.isNotEmpty
          ? Duration.zero
          : widget.hoverDelay,
    );
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (_activeHoveringPointerDevices.isEmpty) return;
    _activeHoveringPointerDevices.remove(event.device);
    if (_activeHoveringPointerDevices.isEmpty) {
      _scheduleDismissTooltip(withDelay: widget.dismissDelay);
    }
  }

  bool ensureTooltipVisible() {
    _timer?.cancel();
    _timer = null;
    if (_controller.isForwardOrCompleted) return false;
    _scheduleShowTooltip(withDelay: Duration.zero);
    return true;
  }

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalPointerEvent,
    );
  }

  Widget _buildTooltipOverlay(
    BuildContext context,
    OverlayChildLayoutInfo layoutInfo,
  ) {
    if (layoutInfo.childPaintTransform.determinant() == 0.0) {
      return const SizedBox.shrink();
    }
    final Offset target = MatrixUtils.transformPoint(
      layoutInfo.childPaintTransform,
      layoutInfo.childSize.center(Offset.zero),
    );

    final Widget tooltip = IgnorePointer(
      ignoring: widget.ignorePointer,
      child: _ExclusiveMouseRegion(
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        child: widget.tooltipBuilder(context, _overlayAnimation),
      ),
    );

    final Widget overlayChild = Positioned.fill(
      bottom: MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0.0,
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          target: target,
          targetSize: layoutInfo.childSize,
          positionDelegate: widget.positionDelegate,
        ),
        child: tooltip,
      ),
    );

    return SelectionContainer.maybeOf(context) == null
        ? overlayChild
        : SelectionContainer.disabled(child: overlayChild);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointerEvent,
    );
    RawTooltip._openedTooltips.remove(this);
    _longPressRecognizer?.onLongPressCancel = null;
    _longPressRecognizer?.dispose();
    _tapRecognizer?.onTapCancel = null;
    _tapRecognizer?.dispose();
    _timer?.cancel();
    _backingController?.dispose();
    _backingOverlayAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.semanticsTooltip?.isEmpty ?? false) return widget.child;
    assert(debugCheckHasOverlay(context));
    final bool excludeFromSemantics =
        widget.semanticsTooltip == null || widget.semanticsTooltip!.isEmpty;
    Widget result = Semantics(
      tooltip: excludeFromSemantics ? null : widget.semanticsTooltip,
      child: widget.child,
    );

    result = _ExclusiveMouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      child: Listener(
        onPointerDown: _handlePointerDown,
        behavior: HitTestBehavior.opaque,
        child: result,
      ),
    );

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayChildBuilder: _buildTooltipOverlay,
      child: result,
    );
  }
}

class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  _TooltipPositionDelegate({
    required this.target,
    required this.targetSize,
    this.positionDelegate,
  });

  final Offset target;
  final Size targetSize;
  final TooltipPositionDelegate? positionDelegate;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    if (positionDelegate != null) {
      return positionDelegate!(
        TooltipPositionContext(
          target: target,
          targetSize: targetSize,
          tooltipSize: childSize,
          overlaySize: size,
          verticalOffset: 0.0,
        ),
      );
    }

    // Default fallback positioning
    double x = target.dx - childSize.width / 2;
    double y = target.dy + targetSize.height / 2 + 8.0;

    const double padding = 8.0;
    if (x < padding) {
      x = padding;
    } else if (x + childSize.width > size.width - padding) {
      x = size.width - childSize.width - padding;
    }

    if (y + childSize.height > size.height - padding) {
      y = target.dy - targetSize.height / 2 - childSize.height - 8.0;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        targetSize != oldDelegate.targetSize ||
        positionDelegate != oldDelegate.positionDelegate;
  }
}

/// A custom styled Tooltip widget that wraps the RawTooltip logic.
class Tooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final bool preferBelow;

  const Tooltip({
    super.key,
    required this.child,
    required this.message,
    this.preferBelow = true,
  });

  @override
  Widget build(BuildContext context) {
    return RawTooltip(
      semanticsTooltip: message,
      tooltipBuilder: (context, animation) {
        return FadeTransition(
          opacity: animation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dark.inverseSurface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.scrim.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: AppText.defaultTheme.labelSmall.copyWith(
                color: AppColors.dark.inverseOnSurface,
              ),
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
      positionDelegate: (context) {
        double x = context.target.dx - context.tooltipSize.width / 2;

        const double padding = 8.0;
        if (x < padding) {
          x = padding;
        } else if (x + context.tooltipSize.width >
            context.overlaySize.width - padding) {
          x = context.overlaySize.width - context.tooltipSize.width - padding;
        }

        double y;
        if (preferBelow) {
          y = context.target.dy + context.targetSize.height / 2 + 8.0;
          if (y + context.tooltipSize.height >
              context.overlaySize.height - padding) {
            y =
                context.target.dy -
                context.targetSize.height / 2 -
                context.tooltipSize.height -
                8.0;
          }
        } else {
          y =
              context.target.dy -
              context.targetSize.height / 2 -
              context.tooltipSize.height -
              8.0;
          if (y < padding) {
            y = context.target.dy + context.targetSize.height / 2 + 8.0;
          }
        }

        return Offset(x, y);
      },
      child: child,
    );
  }
}
