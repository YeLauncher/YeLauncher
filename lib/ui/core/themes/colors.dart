import 'package:flutter/widgets.dart';

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
    primary: Color.fromARGB(255, 6, 147, 62),
    onPrimary: Color.fromARGB(255, 255, 255, 255),
    primaryContainer: Color.fromARGB(255, 108, 249, 164),
    onPrimaryContainer: Color.fromARGB(255, 2, 74, 31),
    inversePrimary: Color.fromARGB(255, 108, 249, 164),
    inverseOnPrimary: Color.fromARGB(255, 4, 98, 42),
    secondary: Color.fromARGB(255, 235, 119, 20),
    onSecondary: Color.fromARGB(255, 255, 255, 255),
    inverseSecondary: Color.fromARGB(255, 243, 174, 114),
    inverseOnSecondary: Color.fromARGB(255, 94, 48, 8),
    surface: Color.fromARGB(255, 15, 15, 15),
    surfaceContainerLowest: Color.fromARGB(255, 10, 10, 10),
    surfaceContainerLow: Color.fromARGB(255, 26, 26, 26),
    surfaceContainer: Color.fromARGB(255, 31, 31, 31),
    surfaceContainerHigh: Color.fromARGB(255, 43, 43, 43),
    surfaceContainerHighest: Color.fromARGB(255, 56, 56, 56),
    onSurface: Color.fromARGB(255, 230, 230, 230),
    onSurfaceVariant: Color.fromARGB(255, 204, 204, 204),
    outline: Color.fromARGB(255, 153, 153, 153),
    outlineVariant: Color.fromARGB(255, 77, 77, 77),
    inverseSurface: Color.fromARGB(255, 230, 230, 230),
    inverseOnSurface: Color.fromARGB(255, 51, 51, 51),
    error: Color.fromARGB(255, 241, 167, 167),
    scrim: Color.fromARGB(255, 0, 0, 0),
  );

  // Light Theme Colors
  static const AppColors light = AppColors(
    primary: Color.fromARGB(255, 6, 147, 62),
    onPrimary: Color.fromARGB(255, 255, 255, 255),
    primaryContainer: Color.fromARGB(255, 108, 249, 164),
    onPrimaryContainer: Color.fromARGB(255, 2, 74, 31),
    inversePrimary: Color.fromARGB(255, 108, 249, 164),
    inverseOnPrimary: Color.fromARGB(255, 4, 98, 42),
    secondary: Color.fromARGB(255, 235, 119, 20),
    onSecondary: Color.fromARGB(255, 255, 255, 255),
    inverseSecondary: Color.fromARGB(255, 243, 174, 114),
    inverseOnSecondary: Color.fromARGB(255, 94, 48, 8),
    surface: Color.fromARGB(255, 15, 15, 15),
    surfaceContainerLowest: Color.fromARGB(255, 10, 10, 10),
    surfaceContainerLow: Color.fromARGB(255, 26, 26, 26),
    surfaceContainer: Color.fromARGB(255, 31, 31, 31),
    surfaceContainerHigh: Color.fromARGB(255, 43, 43, 43),
    surfaceContainerHighest: Color.fromARGB(255, 56, 56, 56),
    onSurface: Color.fromARGB(255, 230, 230, 230),
    onSurfaceVariant: Color.fromARGB(255, 204, 204, 204),
    outline: Color.fromARGB(255, 153, 153, 153),
    outlineVariant: Color.fromARGB(255, 77, 77, 77),
    inverseSurface: Color.fromARGB(255, 230, 230, 230),
    inverseOnSurface: Color.fromARGB(255, 51, 51, 51),
    scrim: Color.fromARGB(255, 0, 0, 0),
    error: Color.fromARGB(255, 154, 25, 25),
  );
}
