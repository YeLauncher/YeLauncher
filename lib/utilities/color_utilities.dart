import 'dart:math';
import 'dart:ui';

final class ColorUtilities {

  /// Universally changes the lightness of a [Color] to a target percentage.
  /// [lightness] - Target lightness ranging from 0.0 (black) to 1.0 (white).
  static Color changeLightness(Color color, double lightness) {
    final double targetL = lightness.clamp(0.0, 1.0);

    // 1. Normalize RGB channels to 0.0 - 1.0 range
    double rNorm = color.red / 255.0;
    double gNorm = color.green / 255.0;
    double bNorm = color.blue / 255.0;

    double maxVal = max(rNorm, max(gNorm, bNorm));
    double minVal = min(rNorm, min(gNorm, bNorm));
    double delta = maxVal - minVal;

    // 2. Calculate Hue and Saturation
    double h = 0.0;
    double s = 0.0;
    double l = (maxVal + minVal) / 2.0;

    if (delta != 0) {
      s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal);

      if (maxVal == rNorm) {
        h = (gNorm - bNorm) / delta + (gNorm < bNorm ? 6.0 : 0.0);
      } else if (maxVal == gNorm) {
        h = (bNorm - rNorm) / delta + 2.0;
      } else {
        h = (rNorm - gNorm) / delta + 4.0;
      }
      h /= 6.0;
    }

    // 3. Convert HSL back to RGB using the requested target lightness
    double rNew, gNew, bNew;

    if (s == 0) {
      rNew = gNew = bNew = targetL; // Achromatic (gray scale)
    } else {
      double hueToRgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      }

      double q = targetL < 0.5 ? targetL * (1.0 + s) : targetL + s - targetL * s;
      double p = 2.0 * targetL - q;

      rNew = hueToRgb(p, q, h + 1 / 3);
      gNew = hueToRgb(p, q, h);
      bNew = hueToRgb(p, q, h - 1 / 3);
    }

    // 4. Scale back to 0-255 bounds and reconstruct ARGB hex code
    int rFinal = (rNew * 255).round();
    int gFinal = (gNew * 255).round();
    int bFinal = (bNew * 255).round();

    int newHex = (color.alpha << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
    return Color(newHex);
  }

  static Color convertHexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha value if not provided
    }
    return Color(int.parse(hex, radix: 16));
  }
}
