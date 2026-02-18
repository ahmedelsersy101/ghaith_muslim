import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/core/sibha/sibha_page.dart';
import 'package:ghaith/helpers/constants.dart';

/// Large highlighted card for the next upcoming prayer
/// Displayed prominently on the prayer times page
class NextPrayerHighlight extends StatelessWidget {
  final String prayerName;
  final String prayerNameArabic;
  final DateTime prayerTime;
  final Duration countdown;

  const NextPrayerHighlight({
    super.key,
    required this.prayerName,
    required this.prayerNameArabic,
    required this.prayerTime,
    required this.countdown,
  });

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  String _formatCountdown(Duration countdown) {
    final hours = countdown.inHours;
    final minutes = countdown.inMinutes.remainder(60);
    final seconds = countdown.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  IconData _getPrayerIcon() {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'dhuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.wb_sunny_outlined;
      case 'maghrib':
        return Icons.nights_stay;
      case 'isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
        borderRadius: BorderRadius.circular(32.r),
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
              borderRadius: BorderRadius.circular(32.r),
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
              borderRadius: BorderRadius.circular(32.r),
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
          Padding(
            padding: EdgeInsets.only(top: 24.h, bottom: 24.h),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isArabic ? 'الصلاة القادمة' : 'NEXT PRAYER',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        fontFamily: 'cairo',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Prayer Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPrayerIcon(),
                        color: Colors.white,
                        size: 25.sp,
                      ),
                    ),
                    // Prayer Name
                    Text(
                      prayerNameArabic,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'cairo',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24.h),
                    // Prayer Time
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        _formatTime(prayerTime),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'roboto',
                        ),
                      ),
                    ),
                    SizedBox(width: 8.h),
                  ],
                ),

                SizedBox(height: 20.h),

                // Countdown
                Column(
                  children: [
                    Text(
                      isArabic ? 'الوقت المتبقي' : 'Time Remaining',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.sp,
                        fontFamily: 'cairo',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _formatCountdown(countdown),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'roboto',
                        letterSpacing: 2,
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
