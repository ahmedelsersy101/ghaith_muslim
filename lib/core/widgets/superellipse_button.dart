// ignore_for_file: unused_field, unused_element, unnecessary_null_comparison, prefer_single_quotes, prefer_interpolation_to_compose_strings
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/main.dart';
import 'package:superellipse_shape/superellipse_shape.dart';

class SuperellipseButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final String imagePath;

  const SuperellipseButton(
      {super.key, required this.text, required this.onPressed, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.2) : Colors.white,
        ),
        child: Material(
          color: isDarkModeNotifier.value
              ? quranPagesColorDark.withOpacity(0.5)
              : quranPagesColorLight,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(24.0.r),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(44.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 8.h,
                ),
                Image.asset(
                  imagePath,
                  height: (MediaQuery.of(context).size.height * .099),
                  // color: const Color(0xffD28A00)
                ),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isDarkModeNotifier.value ? Colors.white70 : Colors.black,
                      fontSize: 16.sp,
                      fontFamily: "cairo"),
                ),
                SizedBox(
                  height: 16.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
