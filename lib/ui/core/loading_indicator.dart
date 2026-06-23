import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

class LoadingIndicator extends StatefulWidget {
  final double size = 48;
  final Color color;
  final Color? trackColor;
  final double strokeWidth;

  LoadingIndicator({
    super.key,
    required this.color,
    this.trackColor,
    this.strokeWidth = 6.0,
  });


  LoadingIndicator.secondary({super.key}): color = AppColors.dark.inverseSecondary,
        trackColor = AppColors.dark.inverseOnSecondary,
        strokeWidth = 6.0;

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headAnimation;
  late Animation<double> _tailAnimation;

  static const double _minFraction = 0.05;
  static const double _maxFraction = 0.75;

  double _cycleOffset = 0.0;

  @override
  void initState() {
    super.initState();

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
        _cycleOffset = (_cycleOffset + _maxFraction) % 1.0;
        _controller.forward(from: 0.0);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Rotate the entire triangle base smoothly over the 1500ms duration
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              painter: _RoundedTrianglePainter(
                color: widget.color,
                trackColor: widget.trackColor,
                strokeWidth: widget.strokeWidth,
                headValue: _headAnimation.value,
                tailValue: _tailAnimation.value,
                cycleOffset: _cycleOffset,
                minFraction: _minFraction,
                maxFraction: _maxFraction,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoundedTrianglePainter extends CustomPainter {
  final Color color;
  final Color? trackColor;
  final double strokeWidth;
  final double headValue;
  final double tailValue;
  final double cycleOffset;
  final double minFraction;
  final double maxFraction;

  _RoundedTrianglePainter({
    required this.color,
    this.trackColor,
    required this.strokeWidth,
    required this.headValue,
    required this.tailValue,
    required this.cycleOffset,
    required this.minFraction,
    required this.maxFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final basePath = Path();
    basePath.moveTo(cx, cy - radius);
    basePath.lineTo(
      cx + radius * math.cos(math.pi / 6),
      cy + radius * math.sin(math.pi / 6),
    );
    basePath.lineTo(
      cx - radius * math.cos(math.pi / 6),
      cy + radius * math.sin(math.pi / 6),
    );
    basePath.close();

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (trackColor != null) {
      final trackPaint = Paint()
        ..color = trackColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(basePath, trackPaint);
    }

    final metrics = basePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final ui.PathMetric metric = metrics.first;
    final double length = metric.length;

    // Calculate length of the stroke
    final double currentFraction = minFraction + (headValue - tailValue) * maxFraction;

    // Calculate start position (removed global rotation since Transform handles it)
    final double startFraction = ((tailValue * maxFraction) + cycleOffset) % 1.0;

    final double startDistance = startFraction * length;
    final double endDistance = startDistance + (currentFraction * length);

    final Path drawPath = Path();

    if (endDistance <= length) {
      drawPath.addPath(metric.extractPath(startDistance, endDistance), Offset.zero);
    } else {
      drawPath.addPath(metric.extractPath(startDistance, length), Offset.zero);
      drawPath.addPath(metric.extractPath(0.0, endDistance % length), Offset.zero);
    }

    canvas.drawPath(drawPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RoundedTrianglePainter oldDelegate) {
    return color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        headValue != oldDelegate.headValue ||
        tailValue != oldDelegate.tailValue;
  }
}

@Preview(name: 'Polygon Loading Indicator')
Widget buildLoadingIndicator() {
  return LoadingIndicator.secondary();
}