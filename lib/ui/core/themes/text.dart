import 'package:flutter/widgets.dart';

class AppText {
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle title;
  final TextStyle titleSmall;
  final TextStyle titleLarge;

  const AppText({
    required this.body,
    required this.bodySmall,
    required this.labelLarge,
    required this.label,
    required this.caption,
    required this.title,
    required this.titleSmall,
    required this.titleLarge,
  });

  static const String _fontFamily = 'Montserrat';

  static const AppText defaultTheme = AppText(
    body: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    label: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    caption: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    title: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
  );
}
