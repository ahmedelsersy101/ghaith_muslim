import 'package:flutter/material.dart';

class ColorUtils {
  static Color blendColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }
}
