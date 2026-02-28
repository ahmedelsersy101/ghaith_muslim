import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/main.dart';

/// Shows a secondary disclosure sheet asking for background (always-on) location access.
/// This is required to be shown separately from foreground permission on Android 11+.
/// Returns `true` if the user tapped "Allow Always" (opens settings), `false` otherwise.
Future<bool?> showBackgroundLocationSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BackgroundLocationSheet(),
  );
}

class _BackgroundLocationSheet extends StatelessWidget {
  const _BackgroundLocationSheet();

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
                Icons.location_searching_rounded,
                color: accentColor,
                size: 36.sp,
              ),
            ),

            SizedBox(height: 20.h),

            // Title
            Text(
              'backgroundLocationTitle'.tr(),
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
              'backgroundLocationBody'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 14.sp,
                height: 1.6,
                color: subtextColor,
              ),
            ),

            SizedBox(height: 28.h),

            // Allow Always button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: Icon(Icons.settings_outlined, size: 18.sp),
                label: Text(
                  'allowAlways'.tr(),
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Skip button
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
                  context.locale.languageCode == 'ar' ? 'تخطي' : 'Skip',
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Privacy Policy Link
            InkWell(
              onTap: () async {
                final url = Uri.parse('https://ahmedelsersy101.github.io/ghaith_p/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  'privacyPolicy'.tr(),
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13.sp,
                    color: accentColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
