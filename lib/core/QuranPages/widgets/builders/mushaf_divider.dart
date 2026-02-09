import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Blend two colors together
Color blendColor(Color a, Color b, double t) {
  return Color.lerp(a, b, t) ?? a;
}

/// Create a tone for mushaf divider based on luminance
Color mushafDividerTone(Color color) {
  final luma = color.computeLuminance();
  final target = luma < 0.45 ? const Color(0xFFF4E6C8) : const Color(0xFF3B2A16);
  final t = luma < 0.45 ? 0.65 : 0.25;
  return blendColor(color, target, t);
}

/// Build mushaf-style decorative divider
class MushafDivider extends StatelessWidget {
  final Color color;
  final double horizontalPadding;

  const MushafDivider({
    Key? key,
    required this.color,
    this.horizontalPadding = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final base = mushafDividerTone(color);
    final lineColor = base.withOpacity(0.5);
    final lightGray = base.withOpacity(0.75);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                border: Border.all(color: lightGray, width: 1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
