import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/main.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghaith/core/prayer/services/location_service.dart';
import 'package:ghaith/core/prayer/components/prominent_disclosure_dialog.dart';
import 'package:location/location.dart' as loc;

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
    final locationService = context.read<LocationService>();

    // ── Case 1: Permission permanently denied → open app settings ──────────
    if (isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    // ── Case 2: Show Prominent Disclosure → System Permission ──────────────
    // Google Play requires the system dialog to appear IMMEDIATELY after
    // the custom disclosure dialog – no screen navigation in between.
    final agreed = await showProminentDisclosureDialog(context);
    if (!agreed || !context.mounted) return;

    // Mark disclosure as seen so it won't appear again
    await locationService.markDisclosureSeen();

    // IMMEDIATELY request foreground permission (system dialog)
    final foregroundStatus = await Permission.location.request();

    if (!context.mounted) return;

    if (foregroundStatus.isGranted || foregroundStatus.isLimited) {
      // Foreground granted → request background (Android 11+ opens settings)
      await Permission.locationAlways.request();

      if (context.mounted) {
        // Immediately trigger loading → shows shimmer while prayer times are fetched
        onRetry();
      }
    } else if (foregroundStatus.isPermanentlyDenied) {
      // User denied permanently from the system dialog
      onRetry();
    } else {
      // User denied but can ask again later
      onRetry();
    }
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

                    // SizedBox(width: 12.w),

                    // // Manual Location Button
                    // Expanded(
                    //   child: OutlinedButton(
                    //     onPressed: () => _navigateToPrayerSettings(context),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Colors.white,
                    //       padding: EdgeInsets.symmetric(vertical: 14.h),
                    //       side: BorderSide(
                    //         color: Colors.white.withOpacity(0.5),
                    //         width: 2,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(16.r),
                    //       ),
                    //     ),
                    //     child: Text(
                    //       'useManualLocation'.tr(),
                    //       style: TextStyle(
                    //         fontSize: 15.sp,
                    //         fontWeight: FontWeight.bold,
                    //         fontFamily: 'cairo',
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
    final location = loc.Location();
    bool isEnabled = await location.requestService();
    // After coming back, if service is enabled, retry loading prayer times
    if (isEnabled) {
      onRetry();
    }
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
