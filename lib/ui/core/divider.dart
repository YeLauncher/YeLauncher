import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';

class HorizontalDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final double indent;
  final double endIndent;
  final Color? color;

  const HorizontalDivider({
    super.key,
    this.height = 16.0,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.dark.outlineVariant;
    
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: thickness,
          margin: EdgeInsetsDirectional.only(start: indent, end: endIndent),
          color: effectiveColor,
        ),
      ),
    );
  }
}

class VerticalDivider extends StatelessWidget {
  final double width;
  final double thickness;
  final double indent;
  final double endIndent;
  final Color? color;

  const VerticalDivider({
    super.key,
    this.width = 16.0,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.dark.outlineVariant;
    
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          width: thickness,
          margin: EdgeInsetsDirectional.only(top: indent, bottom: endIndent),
          color: effectiveColor,
        ),
      ),
    );
  }
}
