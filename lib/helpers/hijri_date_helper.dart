import 'package:hijri/hijri_calendar.dart';

class HijriDateHelper {
  /// الحصول على التاريخ الهجري ناقص يوم واحد
  static HijriCalendar getAdjustedHijriDate() {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    return HijriCalendar.fromDate(yesterday);
  }

  /// الحصول على تاريخ هجري مع التنسيق
  static String getFormattedHijriDate({
    String format = "dd - MMMM - yyyy",
  }) {
    HijriCalendar hijriDate = getAdjustedHijriDate();
    return hijriDate.toFormat(format);
  }
}
