import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

class CircularProgressIndicator extends StatefulWidget {
  final double? value; // If null, runs in indeterminate mode
  final Color color;
  final Color? trackColor;
  final double strokeWidth;
  final double size;

  const CircularProgressIndicator({
    super.key,
    this.value,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 4,
    this.size = 48.0,
  });

  CircularProgressIndicator.primary({super.key, this.value, this.size = 64.0})
      : color = AppColors.dark.inverseSecondary,
        trackColor = AppColors.dark.inverseOnSecondary,
        strokeWidth = 4;

  @override
  State<CircularProgressIndicator> createState() =>
      _CircularProgressIndicatorState();
}

class _CircularProgressIndicatorState extends State<CircularProgressIndicator>
    with TickerProviderStateMixin { // Upgraded to handle multiple controllers

  // Indeterminate Animation Controllers
  late AnimationController _controller;
  late Animation<double> _headAnimation;
  late Animation<double> _tailAnimation;

  // Determinate Smooth Value Controllers
  late AnimationController _valueController;
  late Animation<double> _valueAnimation;

  // Constants for the indeterminate animation physics
  static const double _minSweep = math.pi / 8; // ~22.5 degrees minimum arc length
  static const double _maxSweep = math.pi * 1.5; // 270 degrees stretch

  // Tracks the starting offset for each cycle so the arc doesn't jump back
  double _cycleOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Setup Indeterminate Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOutCubic),
    );

    _tailAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cycleOffset = (_cycleOffset + _maxSweep) % (2 * math.pi);
        _controller.forward(from: 0.0);
      }
    });

    // 2. Setup Determinate Value Smooth Animation Controller
    _valueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Standard M3 transition duration
    );

    _valueAnimation = Tween<double>(
      begin: widget.value ?? 0.0,
      end: widget.value ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _valueController,
      curve: Curves.easeOutCubic, // Decelerates smoothly into the new value
    ));

    // 3. Start the appropriate controller
    if (widget.value == null) {
      _controller.forward();
    } else {
      _valueController.value = 1.0; // Instantly set to target on first build
    }
  }

  @override
  void didUpdateWidget(CircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Transitioning from Determinate -> Indeterminate
    if (widget.value == null && oldWidget.value != null) {
      _valueController.stop();
      _controller.forward();
    }
    // Transitioning from Indeterminate -> Determinate
    else if (widget.value != null && oldWidget.value == null) {
      _controller.stop();
      _valueAnimation = Tween<double>(
          begin: 0.0,
          end: widget.value!
      ).animate(CurvedAnimation(parent: _valueController, curve: Curves.easeOutCubic));
      _valueController.forward(from: 0.0);
    }
    // Updating an existing Determinate value (The Smooth Progress Animation)
    else if (widget.value != null && oldWidget.value != null && widget.value != oldWidget.value) {
      _valueAnimation = Tween<double>(
          begin: _valueAnimation.value, // Start from wherever the animation currently is
          end: widget.value!            // Smoothly tween to the new target
      ).animate(CurvedAnimation(parent: _valueController, curve: Curves.easeOutCubic));
      _valueController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        // Listen to both controllers so the UI updates regardless of which state we are in
        animation: Listenable.merge([_controller, _valueController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _ProgressIndicatorPainter(
              // Pass the smoothly interpolated value if determinate
              value: widget.value != null ? _valueAnimation.value : null,
              color: widget.color,
              trackColor: widget.trackColor,
              strokeWidth: widget.strokeWidth,
              headValue: _headAnimation.value,
              tailValue: _tailAnimation.value,
              rotationValue: _controller.value,
              cycleOffset: _cycleOffset,
              minSweep: _minSweep,
              maxSweep: _maxSweep,
            ),
          );
        },
      ),
    );
  }
}

class _ProgressIndicatorPainter extends CustomPainter {
  final double? value;
  final Color color;
  final Color? trackColor;
  final double strokeWidth;
  final double headValue;
  final double tailValue;
  final double rotationValue;
  final double cycleOffset;
  final double minSweep;
  final double maxSweep;

  // The visual space (in logical pixels) between the active progress and the track
  static const double _visualGap = 4.0;

  _ProgressIndicatorPainter({
    required this.value,
    required this.color,
    this.trackColor,
    required this.strokeWidth,
    required this.headValue,
    required this.tailValue,
    required this.rotationValue,
    required this.cycleOffset,
    required this.minSweep,
    required this.maxSweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    // Adjust radius so the stroke fits perfectly inside the bounding box
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Calculate the angular gap needed to maintain the visual gap.
    // We add the strokeWidth to account for the rounded caps on both the track and the active arc.
    final double gapAngle = (_visualGap + strokeWidth) / radius;

    // 1. Setup the paints
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint? trackPaint = trackColor != null
        ? (Paint()
      ..color = trackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round)
        : null;

    // 2. Draw Determinate (Progress known)
    if (value != null) {
      final double progress = value!.clamp(0.0, 1.0);
      final double startAngle = -math.pi / 2;

      // If progress has started, enforce a tiny minimum sweep so StrokeCap.round renders a perfect dot.
      final double sweepAngle = progress > 0 ? math.max(progress * 2 * math.pi, 0.001) : 0.0;

      if (trackPaint != null) {
        if (sweepAngle == 0) {
          // If 0%, just draw the full background track circle
          canvas.drawCircle(center, radius, trackPaint);
        } else {
          // Draw track with gaps at the ends of the active progress indicator
          final double trackStartAngle = startAngle + sweepAngle + gapAngle;
          final double trackSweepAngle = 2 * math.pi - sweepAngle - (2 * gapAngle);

          // Only draw the track if there is enough space left outside the active progress + gaps
          if (trackSweepAngle > 0) {
            canvas.drawArc(rect, trackStartAngle, trackSweepAngle, false, trackPaint);
          }
        }
      }

      if (sweepAngle > 0) {
        canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
      }
      return;
    }

    // 3. Draw Indeterminate (Loading)
    final double sweepAngle = minSweep + (headValue - tailValue) * maxSweep;
    final double startAngle = -math.pi / 2 +
        (rotationValue * 2 * math.pi) +
        (tailValue * maxSweep) +
        cycleOffset;

    if (trackPaint != null) {
      // Calculate and draw the track with space separating it from the active sweep
      final double trackStartAngle = startAngle + sweepAngle + gapAngle;
      final double trackSweepAngle = 2 * math.pi - sweepAngle - (2 * gapAngle);

      if (trackSweepAngle > 0) {
        canvas.drawArc(rect, trackStartAngle, trackSweepAngle, false, trackPaint);
      }
    }

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressIndicatorPainter oldDelegate) {
    return value != oldDelegate.value ||
        color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        headValue != oldDelegate.headValue ||
        tailValue != oldDelegate.tailValue ||
        rotationValue != oldDelegate.rotationValue;
  }
}