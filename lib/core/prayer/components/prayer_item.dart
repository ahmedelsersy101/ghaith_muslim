import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

/// Individual prayer time list item
/// Shows prayer name, icon, and time
class PrayerItem extends StatelessWidget {
  final String prayerName;
  final String prayerNameArabic;
  final DateTime prayerTime;
  final bool isNextPrayer;
  final bool isSunrise; // Sunrise is not a prayer but should be displayed

  const PrayerItem({
    super.key,
    required this.prayerName,
    required this.prayerNameArabic,
    required this.prayerTime,
    this.isNextPrayer = false,
    this.isSunrise = false,
  });

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  IconData _getPrayerIcon() {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
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

  Color _getPrayerColor(BuildContext context, bool isDark) {
    if (isNextPrayer) {
      return const Color(0xFF8C2F3A);
    }
    if (isSunrise) {
      return Colors.orange.withOpacity(0.8);
    }
    return isDark ? Colors.white.withOpacity(0.7) : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prayerColor = _getPrayerColor(context, isDark);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isNextPrayer
            ? const Color(0xFF8C2F3A).withOpacity(0.1)
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(16.r),
        border: isNextPrayer
            ? Border.all(
                color: const Color(0xFF8C2F3A).withOpacity(0.3),
                width: 2,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isNextPrayer
                ? const Color(0xFF8C2F3A).withOpacity(0.2)
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            _getPrayerIcon(),
            color: prayerColor,
            size: 24.sp,
          ),
        ),
        title: Text(
          prayerNameArabic,
          style: TextStyle(
            color: prayerColor,
            fontSize: 18.sp,
            fontWeight: isNextPrayer ? FontWeight.bold : FontWeight.w600,
            fontFamily: 'cairo',
          ),
        ),
        subtitle: isSunrise
            ? Text(
                isArabic ? 'ليس وقت صلاة' : 'Not a prayer time',
                style: TextStyle(
                  color: prayerColor.withOpacity(0.6),
                  fontSize: 11.sp,
                  fontFamily: 'cairo',
                ),
              )
            : null,
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isNextPrayer
                ? const Color(0xFF8C2F3A).withOpacity(0.2)
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            _formatTime(prayerTime),
            style: TextStyle(
              color: prayerColor,
              fontSize: 16.sp,
              fontWeight: isNextPrayer ? FontWeight.bold : FontWeight.w600,
              fontFamily: 'roboto',
            ),
          ),
        ),
      ),
    );
  }
}
