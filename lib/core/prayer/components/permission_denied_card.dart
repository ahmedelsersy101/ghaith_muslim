import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/main.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ghaith/core/prayer/prayer_times_page.dart';

/// Widget displayed when location permission is denied
/// Shows a user-friendly message and options to grant permission or use manual location
class PermissionDeniedCard extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onRetry;

  const PermissionDeniedCard({
    super.key,
    this.isPermanentlyDenied = false,
    required this.onRetry,
  });

  Future<void> _requestPermission(BuildContext context) async {
    if (isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      // After coming back, retry loading prayer times
      onRetry();
    } else {
      // Request permission again
      final status = await Permission.location.request();
      if (status.isGranted) {
        onRetry();
      }
    }
  }

  void _navigateToPrayerSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrayerTimesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = isDarkModeNotifier.value;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF8C2F3A),
                  const Color(0xFF6a1e2c),
                  const Color(0xFF4a1520),
                ]
              : [
                  const Color(0xFF8C2F3A),
                  const Color(0xFF6a1e2c),
                  const Color(0xFF4a1520),
                ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF8C2F3A) : wineRed).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -16,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
          ),

          // Glossy overlay effect
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    color: Colors.white,
                    size: 48.sp,
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  isPermanentlyDenied
                      ? 'locationPermissionDeniedForeverTitle'.tr()
                      : 'locationPermissionDeniedTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'cairo',
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Message
                Text(
                  isPermanentlyDenied
                      ? 'locationPermissionDeniedForeverMessage'.tr()
                      : 'locationPermissionDeniedMessage'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontFamily: 'cairo',
                    height: 1.6,
                  ),
                ),

                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    // Grant Permission / Open Settings Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _requestPermission(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: wineRed,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          isPermanentlyDenied ? 'openSettings'.tr() : 'grantPermission'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'cairo',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Manual Location Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _navigateToPrayerSettings(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'useManualLocation'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget displayed when location services are disabled
class LocationServiceDisabledCard extends StatelessWidget {
  final VoidCallback onRetry;

  const LocationServiceDisabledCard({
    super.key,
    required this.onRetry,
  });

  Future<void> _openLocationSettings(BuildContext context) async {
    await openAppSettings();
    // After coming back, retry loading prayer times
    onRetry();
  }

  void _navigateToPrayerSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrayerTimesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = isDarkModeNotifier.value;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF8C2F3A),
                  const Color(0xFF6a1e2c),
                  const Color(0xFF4a1520),
                ]
              : [
                  const Color(0xFF8C2F3A),
                  const Color(0xFF6a1e2c),
                  const Color(0xFF4a1520),
                ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF8C2F3A) : wineRed).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -16,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
          ),

          // Glossy overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_disabled_rounded,
                    color: Colors.white,
                    size: 48.sp,
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  'locationServiceDisabledTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'cairo',
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Message
                Text(
                  'locationServiceDisabledMessage'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                    fontFamily: 'cairo',
                    height: 1.6,
                  ),
                ),

                SizedBox(height: 24.h),

                // Buttons
                Row(
                  children: [
                    // Enable Location Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openLocationSettings(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: wineRed,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'enableLocation'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'cairo',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Manual Location Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _navigateToPrayerSettings(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'useManualLocation'.tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for Card Pattern
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
