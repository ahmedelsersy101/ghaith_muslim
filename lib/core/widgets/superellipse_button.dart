// ignore_for_file: unused_field, unused_element, unnecessary_null_comparison, prefer_single_quotes, prefer_interpolation_to_compose_strings
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/helpers/constants.dart';
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isDarkModeNotifier.value
              ? darkSlateGray.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
        ),
        child: Material(
          color: isDarkModeNotifier.value ? darkSlateGray.withOpacity(0.5) : paperBeige,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(24.0.r),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24.r),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 8.h,
                  ),
                  Image.asset(
                    imagePath,
                    height: (MediaQuery.of(context).size.height * .060),
                    // color: const Color(0xffD28A00)
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDarkModeNotifier.value ? Colors.white70 : Colors.black,
                          fontSize: 12.sp,
                          fontFamily: "Taha"),
                    ),
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
