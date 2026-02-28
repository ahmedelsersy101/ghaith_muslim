import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/main.dart';

/// Shows the Prominent Disclosure dialog for location access.
/// This MUST be shown immediately before the system permission dialog
/// to comply with Google Play's Background Location policy.
///
/// Returns `true` if the user tapped "موافقة" (Agree), `false` otherwise.
Future<bool> showProminentDisclosureDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ProminentDisclosureDialog(),
  );
  return result ?? false;
}

class _ProminentDisclosureDialog extends StatelessWidget {
  const _ProminentDisclosureDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;
    final bgColor = isDark ? darkSlateGray : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.65);
    final accentColor = isDark ? wineRed : deepBurgundyRed;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location icon
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
              context.locale.languageCode == 'ar' ? 'إذن الموقع الجغرافي' : 'Location Permission',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            SizedBox(height: 16.h),

            // Exact disclosure text required by Google Play
            Text(
              'يحتاج تطبيق غيث المسلم إلى الوصول لموقعك الحالي لتقديم ميزة أوقات الصلاة واتجاه القبلة بدقة، وذلك حتى عندما يكون التطبيق مغلقاً أو غير مستخدم.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 14.sp,
                height: 1.7,
                color: subtextColor,
              ),
            ),

            SizedBox(height: 20.h),

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
                  Flexible(
                    child: Text(
                      context.locale.languageCode == 'ar'
                          ? 'بياناتك مشفّرة ولا تُشارك مع أطراف خارجية'
                          : 'Your data is encrypted and never shared',
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12.sp,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
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
                  context.locale.languageCode == 'ar' ? 'موافقة' : 'Agree',
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Cancel button
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
                  context.locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel',
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
    );
  }
}
