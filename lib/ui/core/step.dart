import 'package:flutter/widgets.dart';
import 'package:yelauncher/ui/core/themes/colors.dart';
import 'package:yelauncher/ui/core/themes/text.dart';

class Step extends StatefulWidget {
  final String title;
  final IconData iconData;
  final bool isCompleted;
  final bool isCurrent;
  final Color defaultColor;
  final Color currentColor;
  final Color completedBackgroundColor;
  final Color completedIconColor;
  final Color completedTextColor;

  const Step({
    super.key,
    required this.title,
    required this.iconData,
    required this.isCompleted,
    required this.isCurrent,
    required this.defaultColor,
    required this.currentColor,
    required this.completedBackgroundColor,
    required this.completedIconColor,
    required this.completedTextColor,
  });

  Step.primary({
    super.key,
    required this.title,
    required this.iconData,
    required this.isCompleted,
    required this.isCurrent,
  }) : defaultColor = AppColors.dark.onSurfaceVariant,
       currentColor = AppColors.dark.primary,
       completedBackgroundColor = AppColors.dark.primary,
       completedIconColor = AppColors.dark.onPrimary,
       completedTextColor = AppColors.dark.onPrimary;

  @override
  State<StatefulWidget> createState() => _StepState();
}

class _StepState extends State<Step> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 150),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isCompleted
                  ? _backgroundColor
                  : AppColors.transparent,
              border: Border.all(width: 2, color: _backgroundColor),
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                widget.iconData,
                color: _iconColor,
                weight: 600,
                size: 20,
              ),
            ),
          ),
          Text(
            widget.title,
            style: AppText.defaultTheme.caption.copyWith(color: _textColor),
          ),
        ],
      ),
    );
  }

  Color get _iconColor {
    if (widget.isCompleted) {
      return widget.completedIconColor;
    }
    if (widget.isCurrent) {
      return widget.currentColor;
    }
    return widget.defaultColor;
  }

  Color get _backgroundColor {
    if (widget.isCompleted) {
      return widget.completedBackgroundColor;
    }
    if (widget.isCurrent) {
      return widget.currentColor;
    }
    return AppColors.transparent;
  }

  Color get _textColor {
    if (widget.isCompleted) {
      return widget.completedTextColor;
    }
    if (widget.isCurrent) {
      return widget.currentColor;
    }
    return widget.defaultColor;
  }
}
