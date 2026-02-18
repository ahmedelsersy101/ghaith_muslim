import 'package:adhan/adhan.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:intl/intl.dart';

/// Service for calculating and managing Islamic prayer times
/// Uses the Adhan library for accurate prayer time calculations
class PrayerTimesService {
  /// Calculate prayer times for a specific date and location
  ///
  /// [coordinates] - GPS coordinates (latitude, longitude)
  /// [date] - Date for which to calculate prayer times
  /// [method] - Calculation method (defaults to Muslim World League)
  PrayerTimes calculatePrayerTimes(
    Coordinates coordinates,
    DateTime date, {
    CalculationMethod? method,
  }) {
    final params = method?.getParameters() ?? CalculationMethod.muslim_world_league.getParameters();

    // Adjust parameters if needed
    params.madhab = Madhab.shafi; // Can be made configurable

    final dateComponents = DateComponents.from(date);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);
    return prayerTimes;
  }

  /// Get the next prayer time from current time
  /// Returns both the prayer name and time
  NextPrayerInfo getNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();

    // Define prayer times in order
    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr, 'nameAr': 'الفجر'},
      {'name': 'Sunrise', 'time': prayerTimes.sunrise, 'nameAr': 'الشروق'},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr, 'nameAr': 'الظهر'},
      {'name': 'Asr', 'time': prayerTimes.asr, 'nameAr': 'العصر'},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib, 'nameAr': 'المغرب'},
      {'name': 'Isha', 'time': prayerTimes.isha, 'nameAr': 'العشاء'},
    ];

    // Find the next prayer
    for (var prayer in prayers) {
      final prayerTime = prayer['time'] as DateTime;
      if (prayerTime.isAfter(now)) {
        return NextPrayerInfo(
          name: prayer['name'] as String,
          nameArabic: prayer['nameAr'] as String,
          time: prayerTime,
          countdown: prayerTime.difference(now),
        );
      }
    }

    // If no prayer found today, return Fajr of tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowPrayers = calculatePrayerTimes(
      prayerTimes.coordinates,
      tomorrow,
    );

    return NextPrayerInfo(
      name: 'Fajr',
      nameArabic: 'الفجر',
      time: tomorrowPrayers.fajr,
      countdown: tomorrowPrayers.fajr.difference(now),
    );
  }

  /// Get all prayer times for the current day
  AllPrayerTimes getAllPrayerTimes(PrayerTimes prayerTimes) {
    return AllPrayerTimes(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }

  /// Cache prayer times for a specific month
  /// Stores in Hive for offline access
  Future<void> cachePrayerTimesForMonth(
    Coordinates coordinates,
    DateTime month, {
    CalculationMethod? method,
  }) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final Map<String, Map<String, String>> monthPrayerTimes = {};

    // Calculate prayer times for each day of the month
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final prayerTimes = calculatePrayerTimes(coordinates, date, method: method);

      monthPrayerTimes[day.toString()] = {
        'fajr': DateFormat('HH:mm').format(prayerTimes.fajr),
        'sunrise': DateFormat('HH:mm').format(prayerTimes.sunrise),
        'dhuhr': DateFormat('HH:mm').format(prayerTimes.dhuhr),
        'asr': DateFormat('HH:mm').format(prayerTimes.asr),
        'maghrib': DateFormat('HH:mm').format(prayerTimes.maghrib),
        'isha': DateFormat('HH:mm').format(prayerTimes.isha),
      };
    }

    // Store in Hive
    final key = 'prayerTimes/${month.year}/${month.month}';
    await updateValue(key, monthPrayerTimes);
  }

  /// Get cached prayer times for a specific date
  /// Returns null if not cached
  Map<String, String>? getCachedPrayerTimes(DateTime date) {
    final key = 'prayerTimes/${date.year}/${date.month}';
    final monthData = getValue(key);

    if (monthData == null) return null;

    return (monthData[date.day.toString()] as Map<dynamic, dynamic>?)?.cast<String, String>();
  }

  /// Format prayer time based on user preference (12h/24h)
  String formatPrayerTime(DateTime time, {bool use24Hour = false}) {
    if (use24Hour) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('hh:mm a').format(time);
    }
  }

  /// Get calculation method from string name
  CalculationMethod getCalculationMethodByName(String name) {
    switch (name.toLowerCase()) {
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league;
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'moon_sighting_committee':
        return CalculationMethod.moon_sighting_committee;
      case 'north_america':
        return CalculationMethod.north_america;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'singapore':
        return CalculationMethod.singapore;
      default:
        return CalculationMethod.muslim_world_league;
    }
  }

  /// Get all available calculation methods
  List<String> getAvailableCalculationMethods() {
    return [
      'Muslim World League',
      'Egyptian General Authority',
      'Karachi (University of Islamic Sciences)',
      'Umm Al-Qura University, Makkah',
      'Dubai',
      'Moon Sighting Committee',
      'ISNA (North America)',
      'Kuwait',
      'Qatar',
      'Singapore',
    ];
  }
}

/// Model for next prayer information
class NextPrayerInfo {
  final String name;
  final String nameArabic;
  final DateTime time;
  final Duration countdown;

  NextPrayerInfo({
    required this.name,
    required this.nameArabic,
    required this.time,
    required this.countdown,
  });
}

/// Model for all prayer times in a day
class AllPrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  AllPrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// Get prayer time by name
  DateTime? getPrayerTime(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return fajr;
      case 'sunrise':
        return sunrise;
      case 'dhuhr':
        return dhuhr;
      case 'asr':
        return asr;
      case 'maghrib':
        return maghrib;
      case 'isha':
        return isha;
      default:
        return null;
    }
  }
}
