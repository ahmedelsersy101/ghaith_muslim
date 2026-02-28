import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/main.dart';

/// Shows the Prominent Disclosure bottom sheet for location access.
/// Returns `true` if the user tapped "Agree", `false` / `null` otherwise.
Future<bool?> showLocationDisclosureSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LocationDisclosureSheet(),
  );
}

class _LocationDisclosureSheet extends StatelessWidget {
  const _LocationDisclosureSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;
    final bgColor = isDark ? darkSlateGray : paperBeige;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.65);
    final accentColor = isDark ? wineRed : deepBurgundyRed;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              SizedBox(height: 24.h),

              // Icon
              Container(
                width: 72.sp,
                height: 72.sp,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: accentColor,
                  size: 36.sp,
                ),
              ),

              SizedBox(height: 20.h),

              // Title
              Text(
                'locationDisclosureTitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              SizedBox(height: 12.h),

              // Body
              Text(
                'locationDisclosureBody'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 14.sp,
                  height: 1.6,
                  color: subtextColor,
                ),
              ),

              SizedBox(height: 28.h),

              // Privacy badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: accentColor, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      context.locale.languageCode == 'ar'
                          ? 'بياناتك محمية ولا تُشارك مع أطراف خارجية'
                          : 'Your data is protected and never shared',
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12.sp,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              // Agree button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'locationDisclosureAgree'.tr(),
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Not Now button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: subtextColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'locationDisclosureNotNow'.tr(),
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
