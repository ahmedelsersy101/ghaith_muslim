// ignore_for_file: unused_field, unused_element, unnecessary_null_comparison, prefer_single_quotes, prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:ghaith/helpers/home_blocs.dart';
import 'package:ghaith/helpers/home_state.dart';
import 'package:ghaith/core/calender/calender.dart';
import 'package:ghaith/core/settings/settings_view.dart';
import 'package:ghaith/core/widgets/superellipse_button.dart';
import 'package:ghaith/main.dart';
import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/initializeData.dart';
import 'package:ghaith/core/QuranPages/helpers/convertNumberToAr.dart';
import 'package:ghaith/core/QuranPages/views/quran_sura_list.dart';
import 'package:ghaith/core/QuranPages/views/screenshot_preview.dart';
import 'package:ghaith/core/audiopage/views/audio_home_page.dart';
import 'package:ghaith/core/azkar/views/azkar_homepage.dart';
import 'package:ghaith/core/hadith/views/hadithbookspage.dart';
import 'package:ghaith/core/hadith/views/widgets/screenshot_preview.dart';
import 'package:ghaith/core/hadith/models/hadith.dart';
import 'package:ghaith/core/notifications/data/40hadith.dart';
import 'package:ghaith/core/sibha/sibha_page.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:quran/quran.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:after_layout/after_layout.dart';
import 'package:workmanager/workmanager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AfterLayoutMixin, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    _initializeApp();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    super.initState();
  }

  void _initializeApp() {
    checkInAppUpdate();
    checkSalahNotification();
    downloadAndStoreHadithData();
    getAndStoreRecitersData();
    updateDateData();
    initHiveValues();
    loadJsonAsset();
    updateValue("timesOfAppOpen", getValue("timesOfAppOpen") + 1);
    checkForUpdate();
  }

  StreamSubscription<InstallStatus>? _installUpdateSubscription;

  @override
  void dispose() {
    subscription?.cancel();
    subscription2?.cancel();
    _installUpdateSubscription?.cancel();
    _timer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  late Timer _timer;

  Future<void> checkForUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (!updateInfo.flexibleUpdateAllowed) {
        return;
      }

      _installUpdateSubscription?.cancel();
      _installUpdateSubscription = InAppUpdate.installUpdateListener.listen((InstallStatus status) {
        if (status == InstallStatus.downloaded && mounted) {
          _showUpdateDownloadedSnackbar();
        }
      });

      final result = await InAppUpdate.startFlexibleUpdate();

      if (result != AppUpdateResult.success && mounted) {
        _installUpdateSubscription?.cancel();
      }
    } catch (e) {
      if (mounted) {
        _showUpdateErrorSnackbar();
      }
    }
  }

  void _showUpdateDownloadedSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم تنزيل تحديث جديد. هل تريد تثبيته الآن؟'),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'تثبيت',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }

  void _showUpdateErrorSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعذّر التحقق من التحديثات. جرّب لاحقاً أو حدّث من متجر التطبيقات.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> loadJsonAsset() async {
    final String jsonString = await rootBundle.loadString('assets/json/surahs.json');
    final String jsonString2 = await rootBundle.loadString('assets/json/quarters.json');

    setState(() {
      widgejsonData = jsonDecode(jsonString);
      quarterjsonData = jsonDecode(jsonString2);
    });
  }

  void checkSalahNotification() {
    if (getValue("shouldShowSallyNotification") == true) {
      Workmanager().registerOneOffTask("sallahEnable", "sallahEnable");
    } else {
      Workmanager().registerOneOffTask("sallahDisable", "sallahDisable");
    }
  }

  void checkInAppUpdate() async {}

  String getNativeLanguageName(String languageCode) {
    final languageMap = {
      'ar': 'العربية',
      'en': 'English',
      'de': 'Deutsch',
      'am': 'አማርኛ',
      'jp': '日本語',
      'ms': 'Melayu',
      'pt': 'Português',
      'tr': 'Türkçe',
      'ru': 'Русский',
    };
    return languageMap[languageCode] ?? languageCode;
  }

  Future<void> downloadAndStoreHadithData() async {
    await Future.delayed(const Duration(seconds: 1));
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString("hadithlist-100000-${context.locale.languageCode}") == null) {
      await _fetchAndStoreHadithCategories(prefs);
    }
  }

  Future<void> _fetchAndStoreHadithCategories(SharedPreferences prefs) async {
    try {
      Response response = await Dio().get(
          "https://hadeethenc.com/api/v1/categories/list/?language=${context.locale.languageCode}");

      if (response.data != null) {
        final jsonData = json.encode(response.data);
        prefs.setString("categories-${context.locale.languageCode}", jsonData);
        await _fetchHadithsForCategories(prefs, response.data);
      }
    } catch (error) {
      print('Error fetching hadith categories: $error');
    }
  }

  Future<void> _fetchHadithsForCategories(SharedPreferences prefs, List<dynamic> categories) async {
    for (var category in categories) {
      try {
        Response response2 = await Dio().get(
            "https://hadeethenc.com/api/v1/hadeeths/list/?language=${context.locale.languageCode}&category_id=${category["id"]}&per_page=699999");

        if (response2.data != null) {
          await _storeHadithData(prefs, category["id"], response2.data["data"]);
        }
      } catch (error) {
        print('Error fetching hadiths for category ${category["id"]}: $error');
      }
    }
  }

  Future<void> _storeHadithData(
      SharedPreferences prefs, String categoryId, dynamic hadithData) async {
    final jsonData = json.encode(hadithData);
    prefs.setString("hadithlist-$categoryId-${context.locale.languageCode}", jsonData);

    final allHadithsKey = "hadithlist-100000-${context.locale.languageCode}";
    if (prefs.getString(allHadithsKey) == null) {
      prefs.setString(allHadithsKey, jsonData);
    } else {
      final existingData = json.decode(prefs.getString(allHadithsKey)!) as List<dynamic>;
      existingData.addAll(json.decode(jsonData));
      prefs.setString(allHadithsKey, json.encode(existingData));
    }
  }

  Future<void> getAndStoreRecitersData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("Fetching reciters data...");

    try {
      final languageCode = context.locale.languageCode == "ms"
          ? "eng"
          : (context.locale.languageCode == "en" ? "eng" : context.locale.languageCode);

      await _fetchRecitersData(prefs, languageCode);
      await _fetchMoshafData(prefs, languageCode);
      await _fetchSuwarData(prefs, languageCode);

      prefs.setInt("zikrNotificationindex", 0);
      print("Reciters data fetched successfully");
    } catch (error) {
      print('Error while storing reciters data: $error');
    }
  }

  Future<void> _fetchRecitersData(SharedPreferences prefs, String languageCode) async {
    Response response =
        await Dio().get('http://mp3quran.net/api/v3/reciters?language=$languageCode');
    if (response.data != null) {
      prefs.setString("reciters-$languageCode", json.encode(response.data['reciters']));
    }
  }

  Future<void> _fetchMoshafData(SharedPreferences prefs, String languageCode) async {
    Response response2 =
        await Dio().get('http://mp3quran.net/api/v3/moshaf?language=$languageCode');
    if (response2.data != null) {
      prefs.setString("moshaf-$languageCode", json.encode(response2.data));
    }
  }

  Future<void> _fetchSuwarData(SharedPreferences prefs, String languageCode) async {
    Response response3 = await Dio().get('http://mp3quran.net/api/v3/suwar?language=$languageCode');
    if (response3.data != null) {
      prefs.setString("suwar-$languageCode", json.encode(response3.data['suwar']));
    }
  }

  Future<void> getPrayerTimesData() async {
    DateTime dateTime = DateTime.now();

    if (getValue("prayerTimes/${dateTime.year}/${dateTime.month}") == null || reload) {
      await _fetchPrayerTimesFromAPI();
    } else {
      prayerTimes = getValue("prayerTimes/${dateTime.year}/${dateTime.month}");
    }

    await _calculateNextPrayer();
    setState(() => isLoading = false);
    await setAllarmsForTheMonth();
  }

  Future<void> _fetchPrayerTimesFromAPI() async {
    await Geolocator.requestPermission();
    Position geolocation = await Geolocator.getCurrentPosition();

    await _getCurrentLocation(geolocation);

    Response response = await Dio().get(
        "https://api.aladhan.com/v1/calendar/${dateTime.year}/${dateTime.month}?latitude=${geolocation.latitude}&longitude=${geolocation.longitude}");

    updateValue("prayerTimes/${dateTime.year}/${dateTime.month}", response.data);
    prayerTimes = response.data;
  }

  Future<void> _getCurrentLocation(Position geolocation) async {
    final List<Placemark> placemarks =
        await placemarkFromCoordinates(geolocation.latitude, geolocation.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      updateValue("currentCity", place.subAdministrativeArea!);
      updateValue("currentCountry", place.country!);
    }
  }

  Future<void> _calculateNextPrayer() async {
    final currentDateTime = DateTime.now();
    final currentFormattedTime = DateFormat('HH:mm').format(currentDateTime.toUtc());
    var prayerTimings = prayerTimes["data"][dateTime.day]["timings"];

    for (var prayer in prayerTimings.keys) {
      if (currentFormattedTime.compareTo(prayerTimings[prayer]!) < 0) {
        nextPrayer = prayer;
        nextPrayerTime = prayerTimings[prayer]!;
        break;
      }
    }

    if (nextPrayer.isEmpty || _isUnwantedPrayer(nextPrayer)) {
      nextPrayer = 'Fajr';
      nextPrayerTime = prayerTimings['Fajr']!;
    }
  }

  bool _isUnwantedPrayer(String prayer) {
    const unwantedPrayers = ["Imsak", "Firstthird", "Midnight", "Lastthird"];
    return unwantedPrayers.contains(prayer);
  }

  Future<void> setAllarmsForTheMonth() async {
    await Future.delayed(const Duration(seconds: 1));

    for (var entry in prayerTimes["data"]) {
      await _setPrayerAlarmsForDay(entry);
    }

    getAlarms();
  }

  Future<void> _setPrayerAlarmsForDay(Map<String, dynamic> entry) async {
    var dateInfo = entry["date"];
    var gregorianDate = dateInfo["gregorian"];
    var timings = entry["timings"];

    const prayerTimesToUse = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];
    var filteredTimings = timings.entries.where((entry) => prayerTimesToUse.contains(entry.key));

    for (var prayerEntry in filteredTimings) {
      var prayerDateTime = _parsePrayerDateTime(gregorianDate, prayerEntry.value);

      if (prayerDateTime.isAfter(DateTime.now())) {}
    }
  }

  DateTime _parsePrayerDateTime(Map<String, dynamic> gregorianDate, String time) {
    var timeComponents = time.split(' ')[0].split(':');
    var hour = int.parse(timeComponents[0]);
    var minute = int.parse(timeComponents[1].split(' ')[0]);

    return DateTime.utc(
      int.parse(gregorianDate["year"]),
      gregorianDate["month"]["number"],
      int.parse(gregorianDate["day"]),
      hour,
      minute,
    );
  }

  void _updateTimeLeft() {
    final currentDateTime = DateTime.now();
    final nextPrayerTim = DateTime.parse(
        "${DateFormat('yyyy-MM-dd').format(currentDateTime)} ${nextPrayerTime.split(' ')[0]}");

    Duration timeLeft;

    if (nextPrayer == "Fajr" && currentDateTime.isAfter(nextPrayerTim)) {
      final nextDay = nextPrayerTim.add(const Duration(days: 1));
      timeLeft = nextDay.difference(currentDateTime);
    } else {
      timeLeft = nextPrayerTim.difference(currentDateTime);
    }

    timeLeftController.add(timeLeft);
  }

  void getAlarms() async {}

  void getLocationData() {}

  Future<void> updateDateData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    HijriCalendar.setLocal(context.locale.languageCode == "ar" ? "ar" : "en");
    today = HijriCalendar.now();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        body: Navigator(
            onGenerateRoute: ((settings) => MaterialPageRoute(
                settings: settings, builder: (builder) => _buildHomeScaffold(context)))));
  }

  Widget _buildHomeScaffold(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDarkModeNotifier.value ? deepNavyBlack : paperBeige,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildDecorativeBackground(screenSize),
            _buildBody(screenSize),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeBackground(Size screenSize) {
    final isDark = isDarkModeNotifier.value;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  deepNavyBlack,
                  deepNavyBlack,
                  deepNavyBlack.withOpacity(0.95),
                ]
              : [
                  paperBeige.withOpacity(isDark ? 0.4 : 0.08),
                  paperBeige,
                  paperBeige.withOpacity(isDark ? 0.4 : 0.08),
                ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Main pattern
          CustomPaint(
            painter: IslamicBackgroundPainter(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
            ),
            size: Size(screenSize.width, screenSize.height),
          ),

          // Gradient overlays for depth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? wineRed : wineRed).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? deepBurgundyRed : deepBurgundyRed).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Size screenSize) {
    final isDark = isDarkModeNotifier.value;
    final hijriDate = today != null ? today.toFormat("dd - MMMM - yyyy") : "";
    final gregorianDate = DateFormat.yMMMEd(context.locale.languageCode).format(DateTime.now());
    final showPrayer = nextPrayer.isNotEmpty && nextPrayerTime.isNotEmpty;
    final prayerName = _getPrayerDisplayName(nextPrayer);
    final prayerTime = _formatPrayerTime(nextPrayerTime);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: buildCustomBoxDecoration(isDark),
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

          // Content
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Flexible(
                                child: Text(
                                  'main'.tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "cairo",
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 6.w),
                                if (hijriDate.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      hijriDate,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 14.sp,
                                        fontFamily: "cairo",
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Padding(
                            padding: EdgeInsets.only(right: 4.w),
                            child: Text(
                              gregorianDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50.r),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (builder) => const SettingsView()),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Bismillah Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: Text(
                          context.locale.languageCode == "ar"
                              ? "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيم"
                              : "Bismillah",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17.sp,
                            fontFamily: "UthmanicHafs13",
                            fontWeight: FontWeight.w600,
                            height: 1.6,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Prayer Time Card
                if (showPrayer) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
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
                                context.locale.languageCode == "ar"
                                    ? "الصلاة القادمة"
                                    : "Next Prayer",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11.sp,
                                  fontFamily: "cairo",
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Row(
                                children: [
                                  Text(
                                    prayerName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "cairo",
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
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      prayerTime,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: "roboto",
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration buildCustomBoxDecoration(bool isDark) {
    return BoxDecoration(
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
    );
  }

  String _getPrayerDisplayName(String prayer) {
    for (final item in prayers) {
      if (item[0] == prayer) {
        return context.locale.languageCode == "ar" ? item[1] : item[0];
      }
    }
    return prayer;
  }

  String _formatPrayerTime(String time) {
    if (time.isEmpty) return "";
    return time.split(' ')[0];
  }

  BoxDecoration _cardDecoration() {
    final isDark = isDarkModeNotifier.value;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                darkSlateGray.withOpacity(0.6),
                darkSlateGray.withOpacity(0.4),
              ]
            : [
                Colors.white,
                paperBeige.withOpacity(0.95),
              ],
      ),
      borderRadius: BorderRadius.circular(28.r),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildBody(Size screenSize) {
    return SafeArea(
      child: SizedBox(
        width: screenSize.width,
        child: PageTransitionSwitcher(
          transitionBuilder: (
            Widget child,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return FadeThroughTransition(
              fillColor: Colors.transparent,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: [
            ListView(
              padding: EdgeInsets.only(bottom: 24.h),
              children: [
                SizedBox(height: 50.h),
                _buildHeroHeader(screenSize),
                SizedBox(height: 8.h),
                _buildHomeContent(context, screenSize),
              ],
            ),
          ][index],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.w),
      child: Column(
        children: [
          _buildMainButtons(),
          SizedBox(height: 20.h),
          _buildWidgetsSection(screenSize),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    final isDark = isDarkModeNotifier.value;
    return Container(
      decoration: buildCustomBoxDecoration(isDark),
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
          // Grid content
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildGridButtons(),
          ),
        ],
      ),
    );
  }

  void _navigateToQuran() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => SurahListPage(
                  jsonData: widgejsonData,
                  quarterjsonData: quarterjsonData,
                )));
  }

  void _navigateToHadith() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => BlocProvider(
                  create: (context) => hadithPageBloc,
                  child: HadithBooksPage(locale: context.locale.languageCode),
                )));
  }

  Widget _buildGridButtons() {
    return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 4.w,
        mainAxisSpacing: 4.h,
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        children: <Widget>[
          SuperellipseButton(
              text: "quran".tr(),
              onPressed: () => _navigateToQuran(),
              imagePath: isDarkModeNotifier.value
                  ? "assets/images/wqlogo.png"
                  : "assets/images/qlogo.png"),
          SuperellipseButton(
              text: "Hadith".tr(),
              onPressed: () => _navigateToHadith(),
              imagePath: isDarkModeNotifier.value
                  ? "assets/images/wmuhammed.png"
                  : "assets/images/muhammed.png"),
          SuperellipseButton(
              text: "azkar".tr(),
              onPressed: () => _navigateToAzkar(),
              imagePath: isDarkModeNotifier.value
                  ? "assets/images/wazkar.png"
                  : "assets/images/azkar.png"),
          SuperellipseButton(
              text: "audios".tr(),
              onPressed: () => _navigateToAudios(),
              imagePath: isDarkModeNotifier.value
                  ? "assets/images/wquranlogo.png"
                  : "assets/images/quranlogo.png"),
          SuperellipseButton(
              text: "sibha".tr(),
              onPressed: () => _navigateToSibha(),
              imagePath: isDarkModeNotifier.value
                  ? "assets/images/wsibha.png"
                  : "assets/images/sibha.png"),
          SuperellipseButton(
              text: "calender".tr(),
              onPressed: () => _navigateToCalender(),
              imagePath: isDarkModeNotifier.value
                  ? "assets/images/wcalender.png"
                  : "assets/images/calender.png"),
        ]);
  }

  void _navigateToAzkar() {
    Navigator.push(context, MaterialPageRoute(builder: ((context) => const AzkarHomePage())));
  }

  void _navigateToAudios() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => BlocProvider(
                  create: (create) => playerPageBloc,
                  child: RecitersPage(jsonData: widgejsonData),
                )));
  }

  void _navigateToSibha() {
    Navigator.push(context, MaterialPageRoute(builder: (builder) => const SibhaPage()));
  }

  void _navigateToCalender() {
    Navigator.push(context, MaterialPageRoute(builder: (builder) => const CalenderPage()));
  }

  Widget _buildWidgetsSection(Size screenSize) {
    return Column(
      children: [
        _buildQuranVerseWidget(context, screenSize),
        SizedBox(height: 16.h),
        _buildHadithWidget(screenSize),
      ],
    );
  }

  Widget _buildQuranVerseWidget(BuildContext context, Size screenSize) {
    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: Container(
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: suranumber != null ? _buildVerseContent(context, screenSize) : const SizedBox(),
      ),
    );
  }

  Widget _buildVerseContent(BuildContext context, Size screenSize) {
    final isDark = isDarkModeNotifier.value;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkModeNotifier.value
                ? [
                    deepNavyBlack.withOpacity(isDark ? 0.5 : 0.5),
                    deepNavyBlack.withOpacity(isDark ? 0.5 : 0.5),
                  ]
                : [
                    paperBeige.withOpacity(isDark ? 0.05 : 0.5),
                    paperBeige,
                  ]),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildVerseActionsRow(context),
            SizedBox(height: 20.h),

            // Verse Container with highlight
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: buildCustomBoxDecoration(isDark),
              child: _buildVerseText(screenSize),
            ),

            SizedBox(height: 16.h),

            // Verse info with separator
            Row(
              children: [
                Container(
                  height: 1,
                  width: 40.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        (isDark ? wineRed : deepBurgundyRed).withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                _buildVerseInfo(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? wineRed : deepBurgundyRed).withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseActionsRow(BuildContext context) {
    final title = context.locale.languageCode == "ar" ? "آية اليوم" : "Verse of the Day";
    return _buildCardActionsRow(
      title: title,
      icon: Icons.menu_book_rounded,
      onRefresh: _refreshVerse,
      onShare: () => _showShareOptions(context),
    );
  }

  Widget _buildCardActionsRow({
    required String title,
    required IconData icon,
    required VoidCallback onRefresh,
    required VoidCallback onShare,
  }) {
    final isDark = isDarkModeNotifier.value;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? wineRed.withOpacity(0.2) : wineRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? wineRed.withOpacity(0.4) : wineRed.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDark ? wineRed : wineRed,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : charcoalDarkGray,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: "cairo",
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildActionButton(
          icon: Iconsax.refresh,
          color: isDark ? wineRed : mutedGreen,
          onPressed: onRefresh,
        ),
        SizedBox(width: 8.w),
        _buildActionButton(
          icon: Iconsax.share,
          color: isDark ? deepBurgundyRed : deepBurgundyRed,
          onPressed: onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _refreshVerse() {
    setState(() {
      suranumber = Random().nextInt(114) + 1;
      verseNumber = Random().nextInt(getVerseCount(suranumber)) + 1;
    });
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        elevation: 0,
        context: context,
        builder: (ctx) => _buildShareOptionsBottomSheet());
  }

  Widget _buildShareOptionsBottomSheet() {
    final isDark = isDarkModeNotifier.value;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? darkSlateGray : paperBeige,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOptionButton(
                text: "asimage".tr(),
                onPressed: _shareAsImage,
              ),
              _buildShareOptionButton(
                text: "astext".tr(),
                onPressed: _shareAsText,
              ),
            ],
          ),
          SizedBox(height: 30.h)
        ],
      ),
    );
  }

  Widget _buildShareOptionButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    final isDark = isDarkModeNotifier.value;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [wineRed, deepBurgundyRed] : [deepBurgundyRed, deepBurgundyRed],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (isDark ? wineRed : deepBurgundyRed).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              fontFamily: "cairo",
            ),
          ),
        ),
      ),
    );
  }

  void _shareAsImage() {
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => ScreenShotPreviewPage(
                index: 5,
                surahNumber: suranumber,
                jsonData: widgejsonData,
                firstVerse: verseNumber,
                lastVerse: verseNumber)));
  }

  void _shareAsText() {
    Navigator.pop(context);
    var verse = getVerse(suranumber, verseNumber, verseEndSymbol: true);
    var suraName = getSurahNameArabic(suranumber);
    Share.share("$verse \nسورة $suraName");
  }

  Widget _buildVerseText(Size screenSize) {
    final isDark = isDarkModeNotifier.value;
    return Text(
      getVerse(suranumber, verseNumber),
      textAlign: TextAlign.right,
      style: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.95) : Colors.white,
          fontSize: 22.sp,
          height: 1.9,
          fontFamily: "UthmanicHafs13"),
    );
  }

  Widget _buildVerseInfo() {
    final isDark = isDarkModeNotifier.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          convertToArabicNumber(verseNumber.toString()).toString(),
          textAlign: TextAlign.right,
          style: TextStyle(
              color: isDark ? wineRed : deepBurgundyRed,
              fontSize: 26.sp,
              fontFamily: "KFGQPC Uthmanic Script HAFS Regular"),
        ),
        Text(
          " - ",
          style: TextStyle(
            color: isDark ? Colors.white70 : charcoalDarkGray,
          ),
        ),
        if (widgejsonData != null)
          Text(
            widgejsonData[suranumber - 1]["name"],
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: fontFamilies[0],
              color: isDark ? Colors.white.withOpacity(0.9) : mediumGray,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildHadithWidget(Size screenSize) {
    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: Container(
        decoration: _cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: suranumber != null ? _buildHadithContent(screenSize) : const SizedBox(),
      ),
    );
  }

  Widget _buildHadithContent(Size screenSize) {
    final isDark = isDarkModeNotifier.value;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkModeNotifier.value
                ? [
                    deepNavyBlack.withOpacity(isDark ? 0.5 : 0.5),
                    deepNavyBlack.withOpacity(isDark ? 0.5 : 0.5),
                  ]
                : [
                    paperBeige.withOpacity(isDark ? 0.05 : 0.5),
                    paperBeige,
                  ]),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildHadithActionsRow(),
            SizedBox(height: 20.h),

            // Hadith Container with highlight
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: buildCustomBoxDecoration(isDark),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: (isDark ? wineRed : Colors.white),
                    size: 32.sp,
                  ),
                  SizedBox(height: 12.h),
                  _buildHadithText(screenSize),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithActionsRow() {
    final title = context.locale.languageCode == "ar" ? "حديث اليوم" : "Hadith of the Day";
    return _buildCardActionsRow(
      title: title,
      icon: Icons.format_quote_rounded,
      onRefresh: _refreshHadith,
      onShare: () => _showHadithShareOptions(context),
    );
  }

  void _refreshHadith() {
    setState(() {
      indexOfHadith = Random().nextInt(hadithes.length);
    });
  }

  void _showHadithShareOptions(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        elevation: 0,
        context: context,
        builder: (ctx) => _buildHadithShareOptionsBottomSheet());
  }

  Widget _buildHadithShareOptionsBottomSheet() {
    final isDark = isDarkModeNotifier.value;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? darkSlateGray : paperBeige,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareOptionButton(
                text: "asimage".tr(),
                onPressed: _shareHadithAsImage,
              ),
              _buildShareOptionButton(
                text: "astext".tr(),
                onPressed: _shareHadithAsText,
              ),
            ],
          ),
          SizedBox(height: 30.h)
        ],
      ),
    );
  }

  void _shareHadithAsImage() {
    Navigator.pop(context);
    final hadithData = hadithes[indexOfHadith];
    final hadith = Hadith(
      id: indexOfHadith.toString(),
      title: '',
      hadeeth: hadithData["hadith"] ?? '',
      attribution: '',
      grade: '',
      explanation: hadithData["description"] ?? '',
      hints: [],
      categories: [],
      translations: [],
      wordsMeanings: [],
      reference: '',
    );

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (builder) => HadithScreenShotPreviewPage(
                  hadithAr: hadith,
                  hadithOtherLanguage: null,
                  addExplanation: false,
                  addMeanings: false,
                )));
  }

  void _shareHadithAsText() {
    Navigator.pop(context);
    Share.share(hadithes[indexOfHadith]["hadith"]);
  }

  Widget _buildHadithText(Size screenSize) {
    final isDark = isDarkModeNotifier.value;
    return Text(
      hadithes[indexOfHadith]["hadith"],
      textAlign: TextAlign.right,
      style: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.95) : Colors.white,
          fontSize: 22.sp,
          height: 1.9,
          fontFamily: "Taha"),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {}

  @override
  bool get wantKeepAlive => true;
}

// Custom Painter for Islamic Background Pattern
class IslamicBackgroundPainter extends CustomPainter {
  final Color color;

  IslamicBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 60.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw star pattern
        _drawStar(canvas, Offset(x, y), 15, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    const points = 8;
    const angle = (3.14159 * 2) / points;

    for (int i = 0; i < points; i++) {
      final x1 = center.dx + size * cos(angle * i);
      final y1 = center.dy + size * sin(angle * i);
      final x2 = center.dx + (size / 2) * cos(angle * i + angle / 2);
      final y2 = center.dy + (size / 2) * sin(angle * i + angle / 2);

      canvas.drawLine(Offset(x1, y1), center, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Card Pattern
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

        if (x + spacing < size.width) {
          canvas.drawLine(
            Offset(x + 8, y),
            Offset(x + spacing - 8, y),
            paint..strokeWidth = 0.8,
          );
        }
        if (y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y + 8),
            Offset(x, y + spacing - 8),
            paint..strokeWidth = 0.8,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
