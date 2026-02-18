import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/core/sibha/sibha_page.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/main.dart';

/// Compact prayer time card for home screen
/// Shows next prayer with countdown and all prayer times
class PrayerTimeCard extends StatelessWidget {
  final String nextPrayer;
  final String nextPrayerArabic;
  final DateTime prayerTime;
  final Duration countdown;
  final VoidCallback? onTap;

  // All prayer times
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const PrayerTimeCard({
    super.key,
    required this.nextPrayer,
    required this.nextPrayerArabic,
    required this.prayerTime,
    required this.countdown,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.onTap,
  });

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  String _formatCountdown(Duration countdown, bool isArabic) {
    final hours = countdown.inHours;
    final minutes = countdown.inMinutes.remainder(60);

    if (hours > 0) {
      if (isArabic) {
        return 'متبقي $hours ساعة و $minutes دقيقة';
      } else {
        return 'in $hours hours $minutes minutes';
      }
    } else {
      if (isArabic) {
        return 'متبقي $minutes دقيقة';
      } else {
        return 'in $minutes minutes';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkModeNotifier.value
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
              color:
                  (isDarkModeNotifier.value ? const Color(0xFF8C2F3A) : wineRed).withOpacity(0.3),
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
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next Prayer Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'الصلاة القادمة' : 'Next Prayer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11.sp,
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Text(
                                  isArabic ? nextPrayerArabic : nextPrayer,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'cairo',
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: const Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _formatCountdown(countdown, isArabic),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 11.sp,
                                    fontFamily: 'cairo',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 24.sp,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),

                  SizedBox(height: 12.h),

                  // Prayer Times Grid
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 4,
                      children: [
                        _buildPrayerTimeItem(isArabic ? 'الفجر' : 'Fajr', fajr,
                            nextPrayer.toLowerCase() == 'fajr', isArabic),
                        _buildPrayerTimeItem(isArabic ? 'الظهر' : 'Dhuhr', dhuhr,
                            nextPrayer.toLowerCase() == 'dhuhr', isArabic),
                        _buildPrayerTimeItem(isArabic ? 'العصر' : 'Asr', asr,
                            nextPrayer.toLowerCase() == 'asr', isArabic),
                        _buildPrayerTimeItem(isArabic ? 'المغرب' : 'Maghrib', maghrib,
                            nextPrayer.toLowerCase() == 'maghrib', isArabic),
                        _buildPrayerTimeItem(isArabic ? 'العشاء' : 'Isha', isha,
                            nextPrayer.toLowerCase() == 'isha', isArabic),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeItem(String name, DateTime time, bool isNext, bool isArabic) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isNext ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: isNext
            ? Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(isNext ? 1.0 : 0.8),
              fontSize: 12.sp,
              fontFamily: 'cairo',
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTime(time),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'roboto',
            ),
          ),
        ],
      ),
    );
  }
}
