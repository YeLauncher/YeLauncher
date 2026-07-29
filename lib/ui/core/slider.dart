import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

/// A custom slider widget built without Material imports.
///
/// Supports [min], [max], [value], [divisions], and [onChanged].
/// Optionally displays the current value as a label via [valueLabelBuilder].
class AppSlider extends StatefulWidget {
  final double min;
  final double max;
  final double value;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String Function(double value)? valueLabelBuilder;

  const AppSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    this.divisions,
    this.onChanged,
    this.valueLabelBuilder,
  });

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  bool _isDragging = false;

  double get _fraction {
    if (widget.max <= widget.min) return 0;
    return ((widget.value - widget.min) / (widget.max - widget.min))
        .clamp(0.0, 1.0);
  }

  double _fractionFromPosition(Offset localPosition, double trackWidth) {
    final raw = (localPosition.dx / trackWidth).clamp(0.0, 1.0);
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = 1.0 / widget.divisions!;
      return (raw / step).roundToDouble() * step;
    }
    return raw;
  }

  double _valueFromFraction(double fraction) {
    return widget.min + fraction * (widget.max - widget.min);
  }

  void _updateValue(Offset localPosition, double trackWidth) {
    final fraction = _fractionFromPosition(localPosition, trackWidth);
    final newValue = _valueFromFraction(fraction);
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.valueLabelBuilder?.call(widget.value) ??
        widget.value.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: AppText.defaultTheme.labelLarge.copyWith(
              color: AppColors.dark.primary,
            ),
          ),
        ),
        // Slider track
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            return MouseRegion(
              cursor: widget.onChanged != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                onPanStart: widget.onChanged != null
                    ? (details) {
                        setState(() => _isDragging = true);
                        _updateValue(details.localPosition, trackWidth);
                      }
                    : null,
                onPanUpdate: widget.onChanged != null
                    ? (details) =>
                        _updateValue(details.localPosition, trackWidth)
                    : null,
                onPanEnd: widget.onChanged != null
                    ? (_) => setState(() => _isDragging = false)
                    : null,
                onTapDown: widget.onChanged != null
                    ? (details) =>
                        _updateValue(details.localPosition, trackWidth)
                    : null,
                child: SizedBox(
                  height: 32,
                  width: trackWidth,
                  child: CustomPaint(
                    painter: _SliderPainter(
                      fraction: _fraction,
                      isDragging: _isDragging,
                      activeColor: AppColors.dark.primary,
                      inactiveColor:
                          AppColors.dark.outlineVariant.withValues(alpha: 0.5),
                      thumbColor: AppColors.dark.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Min/Max labels
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.valueLabelBuilder?.call(widget.min) ??
                    widget.min.toStringAsFixed(0),
                style: AppText.defaultTheme.caption.copyWith(
                  color: AppColors.dark.onSurfaceVariant,
                ),
              ),
              Text(
                widget.valueLabelBuilder?.call(widget.max) ??
                    widget.max.toStringAsFixed(0),
                style: AppText.defaultTheme.caption.copyWith(
                  color: AppColors.dark.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  final double fraction;
  final bool isDragging;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  _SliderPainter({
    required this.fraction,
    required this.isDragging,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 6.0;
    final thumbRadius = isDragging ? 10.0 : 8.0;
    final centerY = size.height / 2;
    final trackTop = centerY - trackHeight / 2;

    // Inactive track (full width, drawn first as background)
    final inactivePaint = Paint()..color = inactiveColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, size.width, trackHeight),
        const Radius.circular(3),
      ),
      inactivePaint,
    );

    // Active track
    final activeWidth = fraction * size.width;
    if (activeWidth > 0) {
      final activePaint = Paint()..color = activeColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, trackTop, activeWidth, trackHeight),
          const Radius.circular(3),
        ),
        activePaint,
      );
    }

    // Thumb
    final thumbX = fraction * size.width;
    final thumbPaint = Paint()..color = thumbColor;

    // Shadow
    canvas.drawCircle(
      Offset(thumbX, centerY + 1),
      thumbRadius + 1,
      Paint()..color = const Color(0x33000000),
    );

    canvas.drawCircle(
      Offset(thumbX, centerY),
      thumbRadius,
      thumbPaint,
    );

    // Inner white dot
    canvas.drawCircle(
      Offset(thumbX, centerY),
      thumbRadius * 0.4,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        isDragging != oldDelegate.isDragging;
  }
}
