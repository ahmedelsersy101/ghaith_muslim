import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../utils/color_utils.dart';

class MushafDivider extends StatelessWidget {
  final Color color;

  const MushafDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final base = _mushafDividerTone(color);
    final lineColor = base.withOpacity(0.5);
    final lightGray = base.withOpacity(0.75);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          SizedBox(width: 8.w),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                border: Border.all(color: lightGray, width: 1),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }

  Color _mushafDividerTone(Color color) {
    final luma = color.computeLuminance();
    final target = luma < 0.45 ? const Color(0xFFF4E6C8) : const Color(0xFF3B2A16);
    final t = luma < 0.45 ? 0.65 : 0.25;
    return ColorUtils.blendColor(color, target, t);
  }
}
