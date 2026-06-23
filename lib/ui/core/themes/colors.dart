import 'package:flutter/widgets.dart';
import 'package:yelauncher/utilities/color_utilities.dart';

final class AppColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color inversePrimary;
  final Color inverseOnPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color inverseSecondary;
  final Color inverseOnSecondary;

  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color scrim;

  final Color error;

  static Color get transparent => const Color(0x00000000);

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.inverseOnPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.inverseSecondary,
    required this.inverseOnSecondary,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.scrim,
    required this.error,
  });

  // Dark Theme Colors
  static const AppColors dark = AppColors(
    primary: Color(0xFF06933E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF6CF9A4),
    onPrimaryContainer: Color(0xFF024A1F),
    inversePrimary: Color(0xFF6CF9A4),
    inverseOnPrimary: Color(0xFF04622A),
    secondary: Color(0xFFEB7714),
    onSecondary: Color(0xFFFFFFFF),
    inverseSecondary: Color(0xFFF3AE72),
    inverseOnSecondary: Color(0xFF5E3008),
    surface: Color(0xFF0F0F0F),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF1F1F1F),
    surfaceContainerHigh: Color(0xFF2B2B2B),
    surfaceContainerHighest: Color(0xFF383838),
    onSurface: Color(0xFFE6E6E6),
    onSurfaceVariant: Color(0xFFCCCCCC),
    outline: Color(0xFF999999),
    outlineVariant: Color(0xFF4D4D4D),
    inverseSurface: Color(0xFFE6E6E6),
    inverseOnSurface: Color(0xFF333333),
    error: Color(0xFFF1A7A7),
    scrim: Color(0xFF000000),
  );

  // Light Theme Colors
  static const AppColors light = AppColors(
    primary: Color(0xFF06933E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF6CF9A4),
    onPrimaryContainer: Color(0xFF024A1F),
    inversePrimary: Color(0xFF6CF9A4),
    inverseOnPrimary: Color(0xFF04622A),
    secondary: Color(0xFFEB7714),
    onSecondary: Color(0xFFFFFFFF),
    inverseSecondary: Color(0xFFF3AE72),
    inverseOnSecondary: Color(0xFF5E3008),
    surface: Color(0xFF0F0F0F),
    surfaceContainerLowest: Color(0xFF0A0A0A),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF1F1F1F),
    surfaceContainerHigh: Color(0xFF2B2B2B),
    surfaceContainerHighest: Color(0xFF383838),
    onSurface: Color(0xFFE6E6E6),
    onSurfaceVariant: Color(0xFFCCCCCC),
    outline: Color(0xFF999999),
    outlineVariant: Color(0xFF4D4D4D),
    inverseSurface: Color(0xFFE6E6E6),
    inverseOnSurface: Color(0xFF333333),
    scrim: Color(0xFF000000),
    error: Color(0xFF9A1919),
  );

  static Color convertToContainerColor(Color color) {
    return ColorUtilities.changeLightness(color, 0.7);
  }

  static Color convertToOnContainerColor(Color color) {
    return ColorUtilities.changeLightness(color, 0.2);
  }
}