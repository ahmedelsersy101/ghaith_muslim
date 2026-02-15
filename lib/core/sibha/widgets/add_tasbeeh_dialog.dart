import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/main.dart';

class AddTasbeehDialog extends StatefulWidget {
  final Function function;

  const AddTasbeehDialog({super.key, required this.function});

  @override
  State<AddTasbeehDialog> createState() => _AddTasbeehDialogState();
}

class _AddTasbeehDialogState extends State<AddTasbeehDialog> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;
    final backgroundColor = isDark ? deepNavyBlack : paperBeige;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20.r),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: textColor.withOpacity(0.7),
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Add To Sibha".tr(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: "cairo",
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: textEditingController,
                autofocus: true,
                cursorColor: textColor,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.sp,
                  fontFamily: "cairo",
                ),
                decoration: InputDecoration(
                  hintText: "Enter Custom Zikr".tr(),
                  hintStyle: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 13.sp,
                  ),
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      width: 1,
                      color: borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      width: 1.5,
                      color: textColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          side: BorderSide(
                            color: borderColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        "cancel".tr(),
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: "cairo",
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (textEditingController.text.trim().isNotEmpty) {
                          widget.function(textEditingController.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: isDark ? Colors.black : Colors.white,
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            "Add".tr(),
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: "cairo",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
