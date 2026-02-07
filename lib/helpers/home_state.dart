import 'dart:async';
import 'dart:math';

import 'package:ghaith/core/notifications/data/40hadith.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran/quran.dart';

var widgejsonData;
var quarterjsonData;
StreamSubscription? subscription;
StreamSubscription? subscription2;
bool alarm = false;
bool alarm1 = false;
int? id;
int suranumber = Random().nextInt(114) + 1;
int indexOfHadith = Random().nextInt(hadithes.length);
int verseNumber = Random().nextInt(getVerseCount(suranumber)) + 1;
late Timer timer;
late StreamController<Duration> timeLeftController;
late Stream<Duration> timeLeftStream;

DateTime dateTime = DateTime.now();
var prayerTimes;
bool isLoading = true;
bool reload = false;
String nextPrayer = '';
String nextPrayerTime = '';
int index = 0;
var today = HijriCalendar.now();
String currentCity = "";
String currentCountry = "";
List prayers = [
  ["Fajr", "الفجر"],
  ["Sunrise", "الشروق"],
  ["Dhuhr", "الظهر"],
  ["Asr", "العصر"],
  ["Maghrib", "المغرب"],
  ["Isha", "العشاء"]
];
