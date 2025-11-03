// ignore_for_file: unused_field, unused_element, unnecessary_null_comparison, prefer_single_quotes, prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:ghaith/core/calender/calender.dart';
import 'package:ghaith/core/settings/settings_view.dart';
import 'package:ghaith/core/widgets/superellipse_button.dart';
import 'package:ghaith/main.dart';
import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/blocs/bloc/bloc/player_bar_bloc.dart';
import 'package:ghaith/blocs/bloc/hadith_bloc.dart';
import 'package:ghaith/blocs/bloc/player_bloc_bloc.dart';
import 'package:ghaith/blocs/bloc/quran_page_player_bloc.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/initializeData.dart';
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
import 'package:quran/quran.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:after_layout/after_layout.dart';
import 'package:workmanager/workmanager.dart';

// 🔹 [CAN_BE_EXTRACTED] يمكن نقل الـ Blocs لملف blocs/home_blocs.dart
final qurapPagePlayerBloc = QuranPagePlayerBloc();
final playerPageBloc = PlayerBlocBloc();
final playerbarBloc = PlayerBarBloc();
final hadithPageBloc = HadithBloc();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with AfterLayoutMixin, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل متغيرات الحالة لملف state/home_state.dart
  var widgejsonData;
  var quarterjsonData;
  StreamSubscription? _subscription;
  StreamSubscription? _subscription2;
  bool alarm = false;
  bool alarm1 = false;
  int? id;
  late int suranumber = Random().nextInt(114) + 1;
  late int indexOfHadith = Random().nextInt(hadithes.length);
  late int verseNumber = Random().nextInt(getVerseCount(suranumber)) + 1;

  late StreamController<Duration> _timeLeftController;
  late Stream<Duration> _timeLeftStream;

  DateTime dateTime = DateTime.now();
  var prayerTimes;
  bool isLoading = true;
  bool reload = false;
  String nextPrayer = '';
  String nextPrayerTime = '';
  int index = 0;
  var _today = HijriCalendar.now();
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

  @override
  void initState() {
    _initializeApp();
    super.initState();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل التهيئة لملف services/app_initializer.dart
  void _initializeApp() {
    checkInAppUpdate();
    checkSalahNotification();
    downloadAndStoreHadithData();
    getAndStoreRecitersData();
    updateDateData();
    initHiveValues();
    loadJsonAsset();
    updateValue("timesOfAppOpen", getValue("timesOfAppOpen") + 1);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription2?.cancel();
    _timer.cancel();
    super.dispose();
  }

  late Timer _timer;

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف JSON لملف services/json_loader.dart
  Future<void> loadJsonAsset() async {
    final String jsonString = await rootBundle.loadString('assets/json/surahs.json');
    final String jsonString2 = await rootBundle.loadString('assets/json/quarters.json');

    setState(() {
      widgejsonData = jsonDecode(jsonString);
      quarterjsonData = jsonDecode(jsonString2);
    });
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف الإشعارات لملف services/notification_service.dart
  void checkSalahNotification() {
    if (getValue("shouldShowSallyNotification") == true) {
      Workmanager().registerOneOffTask("sallahEnable", "sallahEnable");
    } else {
      Workmanager().registerOneOffTask("sallahDisable", "sallahDisable");
    }
  }

  void checkInAppUpdate() async {}

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف اللغة لملف utils/language_utils.dart
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

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف الحديث لملف services/hadith_service.dart
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
          "https://hadeethenc.com/api/v1/categories/roots/?language=${context.locale.languageCode}");

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

    // Add to all hadiths collection
    final allHadithsKey = "hadithlist-100000-${context.locale.languageCode}";
    if (prefs.getString(allHadithsKey) == null) {
      prefs.setString(allHadithsKey, jsonData);
    } else {
      final existingData = json.decode(prefs.getString(allHadithsKey)!) as List<dynamic>;
      existingData.addAll(json.decode(jsonData));
      prefs.setString(allHadithsKey, json.encode(existingData));
    }
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف القرآن لملف services/quran_service.dart
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

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف الصلاة لملف services/prayer_time_service.dart
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

    _timeLeftController.add(timeLeft);
  }

  void getAlarms() async {}

  void getLocationData() {}

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل وظائف التاريخ الهجري لملف utils/hijri_date_utils.dart
  Future<void> updateDateData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    HijriCalendar.setLocal(context.locale.languageCode == "ar" ? "ar" : "en");
    _today = HijriCalendar.now();
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

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل واجهة المستخدم لملف ui/home_screen.dart
  Widget _buildHomeScaffold(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(0.7) : quranPagesColorLight,
      appBar: _buildAppBar(),
      body: _buildBody(screenSize),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor:
          isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.5) : quranPagesColorLight,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'main'.tr(),
            style: TextStyle(
                color: isDarkModeNotifier.value ? backgroundColor : Colors.black,
                fontFamily: "cairo",
                fontSize: 32.sp),
          ),
        ],
      ),
      leading: IconButton(
          onPressed: () {
            Navigator.push(context, CupertinoPageRoute(builder: (builder) => const SettingsView()));
          },
          icon: Icon(
            Icons.settings,
            color: isDarkModeNotifier.value ? backgroundColor : Colors.black,
          )),
    );
  }

  Widget _buildBody(Size screenSize) {
    return SizedBox(
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
          SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildDateSection(),
                SizedBox(height: 10.h),
                _buildHomeContent(context, screenSize),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ][index],
      ),
    );
  }

  Widget _buildDateSection() {
    if (_today == null) return SizedBox(height: 20.h);

    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 20.h),
          Text(
            _today.toFormat("dd - MMMM - yyyy"),
            style: _dateTextStyle(),
          ),
          Text(
            DateFormat.yMMMEd(context.locale.languageCode).format(DateTime.now()),
            style: _dateTextStyle(),
          ),
        ],
      ),
    );
  }

  TextStyle _dateTextStyle() {
    return TextStyle(
        color: isDarkModeNotifier.value ? Colors.white70 : Colors.black, fontSize: 18.sp);
  }

  Widget _buildHomeContent(BuildContext context, Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.0.w),
      child: SizedBox(
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMainButtons(),
            _buildWidgetsSection(screenSize),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButtons() {
    return Column(
      children: [
        // SizedBox(
        //   width: double.infinity,
        //   child: SuperellipseButton(
        //       text: "quran".tr(),
        //       onPressed: () => _navigateToQuran(),
        //       imagePath: isDarkModeNotifier.value
        //           ? "assets/images/wqlogo.png"
        //           : "assets/images/qlogo.png"),
        // ),
        // SizedBox(
        //   width: double.infinity,
        //   child: SuperellipseButton(
        //       text: "Hadith".tr(),
        //       onPressed: () => _navigateToHadith(),
        //       imagePath: isDarkModeNotifier.value
        //           ? "assets/images/wmuhammed.png"
        //           : "assets/images/muhammed.png"),
        // ),
        _buildGridButtons(),
      ],
    );
  }

  void _navigateToQuran() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (builder) => SurahListPage(
                  jsonData: widgejsonData,
                  quarterjsonData: quarterjsonData,
                )));
  }

  void _navigateToHadith() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (builder) => BlocProvider(
                  create: (context) => hadithPageBloc,
                  child: HadithBooksPage(locale: context.locale.languageCode),
                )));
  }

  Widget _buildGridButtons() {
    return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 2,
        mainAxisSpacing: 4,
        crossAxisCount: 2,
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
    Navigator.push(context, CupertinoPageRoute(builder: ((context) => const AzkarHomePage())));
  }

  void _navigateToAudios() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (builder) => BlocProvider(
                  create: (create) => playerPageBloc,
                  child: RecitersPage(jsonData: widgejsonData),
                )));
  }

  void _navigateToSibha() {
    Navigator.push(context, CupertinoPageRoute(builder: (builder) => const SibhaPage()));
  }

  void _navigateToCalender() {
    Navigator.push(context, CupertinoPageRoute(builder: (builder) => const CalenderPage()));
  }

  Widget _buildWidgetsSection(Size screenSize) {
    return Column(
      children: [
        _buildQuranVerseWidget(context, screenSize),
        _buildHadithWidget(screenSize),
      ],
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل ويدجت الآية لملف widgets/quran_verse_widget.dart
  Widget _buildQuranVerseWidget(BuildContext context, Size screenSize) {
    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 6.h),
        child: Material(
          color: isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.2) : Colors.white,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(40.0.r)),
          child: suranumber != null ? _buildVerseContent(context, screenSize) : Container(),
        ),
      ),
    );
  }

  Widget _buildVerseContent(BuildContext context, Size screenSize) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
            color: isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight.withOpacity(.6),
            borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              _buildVerseActionsRow(context),
              SizedBox(height: 20.h),
              _buildVerseText(screenSize),
              _buildVerseInfo(),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseActionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Iconsax.refresh,
          color: orangeColor,
          onPressed: _refreshVerse,
        ),
        _buildActionButton(
          icon: Iconsax.share,
          color: isDarkModeNotifier.value ? orangeColor : blueColor,
          onPressed: () => _showShareOptions(context),
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: IconButton(onPressed: onPressed, icon: Icon(icon, color: Colors.white, size: 18.sp)),
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
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 15.h),
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
    return Container(
      decoration:
          BoxDecoration(color: quranPagesColorDark, borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: TextButton(
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            )),
      ),
    );
  }

  void _shareAsImage() {
    Navigator.pop(context); // إغلاق bottom sheet
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (builder) => ScreenShotPreviewPage(
                index: 5,
                surahNumber: suranumber,
                jsonData: widgejsonData,
                firstVerse: verseNumber,
                lastVerse: verseNumber)));
  }

  void _shareAsText() {
    Navigator.pop(context); // إغلاق bottom sheet
    var verse = getVerse(suranumber, verseNumber, verseEndSymbol: true);
    var suraName = getSurahNameArabic(suranumber);
    Share.share("$verse \nسورة $suraName");
  }

  Widget _buildVerseText(Size screenSize) {
    return SizedBox(
      width: screenSize.width * .8,
      child: Text(
        getVerse(suranumber, verseNumber),
        textAlign: TextAlign.right,
        style: TextStyle(
            color: isDarkModeNotifier.value ? Colors.white70 : Colors.black,
            fontSize: 22.sp,
            fontFamily: "UthmanicHafs13"),
      ),
    );
  }

  Widget _buildVerseInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          convertToArabicNumber(verseNumber.toString()).toString(),
          textAlign: TextAlign.right,
          style: TextStyle(
              color: orangeColor,
              fontSize: 26.sp,
              fontFamily: "KFGQPC Uthmanic Script HAFS Regular"),
        ),
        const Text(" - "),
        if (widgejsonData != null)
          Text(
            widgejsonData[suranumber - 1]["name"],
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: fontFamilies[0],
              color: isDarkModeNotifier.value ? Colors.white70 : blueColor,
              fontSize: 18.sp,
            ),
          ),
      ],
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل ويدجت الحديث لملف widgets/hadith_widget.dart
  Widget _buildHadithWidget(Size screenSize) {
    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 6.h),
        child: Material(
          color: isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.2) : Colors.white,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(40.0.r)),
          child: suranumber != null ? _buildHadithContent(screenSize) : Container(),
        ),
      ),
    );
  }

  Widget _buildHadithContent(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
            color: isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight.withOpacity(.6),
            borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              _buildHadithActionsRow(),
              SizedBox(height: 10.h),
              _buildHadithText(screenSize),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHadithActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Iconsax.refresh,
          color: orangeColor,
          onPressed: _refreshHadith,
        ),
        _buildActionButton(
          icon: Iconsax.share,
          color: isDarkModeNotifier.value ? orangeColor : blueColor,
          onPressed: () => _showHadithShareOptions(context),
        ),
      ],
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
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 15.h),
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
    Navigator.pop(context); // إغلاق bottom sheet
    // إنشاء Hadith object من البيانات المتاحة
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
        CupertinoPageRoute(
            builder: (builder) => HadithScreenShotPreviewPage(
                  hadithAr: hadith,
                  hadithOtherLanguage: null,
                  addExplanation: false,
                  addMeanings: false,
                )));
  }

  void _shareHadithAsText() {
    Navigator.pop(context); // إغلاق bottom sheet
    Share.share(hadithes[indexOfHadith]["hadith"]);
  }

  Widget _buildHadithText(Size screenSize) {
    return SizedBox(
      width: screenSize.width * .8,
      child: Text(
        hadithes[indexOfHadith]["hadith"],
        textAlign: TextAlign.right,
        style: TextStyle(
            color: isDarkModeNotifier.value ? Colors.white70 : Colors.black,
            fontSize: 17.sp,
            fontFamily: "Taha"),
      ),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {}

  @override
  bool get wantKeepAlive => true;
}
