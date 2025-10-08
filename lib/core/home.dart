// ignore_for_file: unused_field, unused_element, unnecessary_null_comparison, prefer_single_quotes, prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:ghaith/core/calender/calender.dart';
import 'package:ghaith/core/notifications/views/all_notification_page.dart';
import 'package:ghaith/core/settings/settings_view.dart';
import 'package:ghaith/core/widgets/superellipse_button.dart';
import 'package:ghaith/main.dart';
import 'package:in_app_review/in_app_review.dart';
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
import 'package:ghaith/core/allah_names/allah_names_page.dart';
import 'package:ghaith/core/audiopage/views/audio_home_page.dart';
import 'package:ghaith/core/azkar/views/azkar_homepage.dart';
import 'package:ghaith/core/hadith/views/hadithbookspage.dart';
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
  Future<void> loadJsonAsset() async {
    final String jsonString = await rootBundle.loadString('assets/json/surahs.json');
    var data = jsonDecode(jsonString);
    setState(() {
      widgejsonData = data;
    });
    final String jsonString2 = await rootBundle.loadString('assets/json/quarters.json');
    var data2 = jsonDecode(jsonString2);
    setState(() {
      quarterjsonData = data2;
    });
  }

  checkSalahNotification() {
    if (getValue("shouldShowSallyNotification") == true) {
      Workmanager().registerOneOffTask("sallahEnable", "sallahEnable");
    } else {
      Workmanager().registerOneOffTask("sallahDisable", "sallahDisable");
    }
  }

  late Timer _timer;
  var _today = HijriCalendar.now();
  showDialogForRate() async {
    if (getValue("timesOfAppOpen") > 2 && getValue("showedDialog") == false) {
      if (await InAppReview.instance.isAvailable()) {
        await InAppReview.instance.requestReview();
        updateValue("showedDialog", true);
      }
    }
  }

  checkInAppUpdate() async {}
  @override
  void initState() {
    showDialogForRate();
    checkInAppUpdate();
    //checkAzanRinging() ;
    checkSalahNotification();
    downloadAndStoreHadithData();
    getAndStoreRecitersData();
    updateDateData();
    initHiveValues();
    super.initState();
    loadJsonAsset();
    updateValue("timesOfAppOpen", getValue("timesOfAppOpen") + 1);
  }

  @override
  // ignore: unnecessary_overrides
  void dispose() {
    super.dispose();
  }

  String getNativeLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'am':
        return 'አማርኛ';
      case 'jp':
        return '日本語';
      case 'ms':
        return 'Melayu';
      case 'pt':
        return 'Português';
      case 'tr':
        return 'Türkçe';
      case 'ru':
        return 'Русский';
      default:
        return languageCode; // Return the language code if not found
    }
  }

  late StreamController<Duration> _timeLeftController;
  late Stream<Duration> _timeLeftStream;
  downloadAndStoreHadithData() async {
    await Future.delayed(const Duration(seconds: 1));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("hadithlist-100000-${context.locale.languageCode}") == null) {
      Response response = await Dio().get(
          "https://hadeethenc.com/api/v1/categories/roots/?language=${context.locale.languageCode}");

      if (response.data != null) {
        final jsonData = json.encode(response.data);
        prefs.setString("categories-${context.locale.languageCode}", jsonData);

        response.data.forEach((category) async {
          Response response2 = await Dio().get(
              "https://hadeethenc.com/api/v1/hadeeths/list/?language=${context.locale.languageCode}&category_id=${category["id"]}&per_page=699999");

          if (response2.data != null) {
            final jsonData = json.encode(response2.data["data"]);
            prefs.setString(
                "hadithlist-${category["id"]}-${context.locale.languageCode}", jsonData);

            ///add to category of all hadithlist
            if (prefs.getString("hadithlist-100000-${context.locale.languageCode}") == null) {
              prefs.setString("hadithlist-100000-${context.locale.languageCode}", jsonData);
            } else {
              final dataOfOldHadithlist =
                  json.decode(prefs.getString("hadithlist-100000-${context.locale.languageCode}")!)
                      as List<dynamic>;
              dataOfOldHadithlist.addAll(json.decode(jsonData));
              prefs.setString("hadithlist-100000-${context.locale.languageCode}",
                  json.encode(dataOfOldHadithlist));
            }
          }
        });
      }
    }

    //  if (response.data != null) {
    //       final jsonData = json.encode(response.data['reciters']);
    //       prefs.setString(
    //           "reciters-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
    //           jsonData);
    //     }
  }

  getAndStoreRecitersData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("working");
    Response response;
    Response response2;
    Response response3;
    try {
      if (context.locale.languageCode == "ms") {
        response = await Dio().get('http://mp3quran.net/api/v3/reciters?language=eng');
        response2 = await Dio().get('http://mp3quran.net/api/v3/moshaf?language=eng');
        response3 = await Dio().get('http://mp3quran.net/api/v3/suwar?language=eng');
      } else {
        response = await Dio().get(
            'http://mp3quran.net/api/v3/reciters?language=${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}');
        response2 = await Dio().get(
            'http://mp3quran.net/api/v3/moshaf?language=${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}');
        response3 = await Dio().get(
            'http://mp3quran.net/api/v3/suwar?language=${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}');
      }

      if (response.data != null) {
        final jsonData = json.encode(response.data['reciters']);
        prefs.setString(
            "reciters-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
            jsonData);
      }
      if (response2.data != null) {
        final jsonData2 = json.encode(response2.data);
        prefs.setString(
            "moshaf-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
            jsonData2);
      }
      if (response3.data != null) {
        final jsonData3 = json.encode(response3.data['suwar']);
        prefs.setString(
            "suwar-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
            jsonData3);
      }
      print("worked");
    } catch (error) {
      print('Error while storing data: $error');
    }

    prefs.setInt("zikrNotificationindex", 0);
  }

  DateTime dateTime = DateTime.now();

  var prayerTimes;
  bool isLoading = true;
  bool reload = false;
  getPrayerTimesData() async {
    DateTime dateTime = DateTime.now();
    if (getValue("prayerTimes/${dateTime.year}/${dateTime.month}") == null || reload) {
      await Geolocator.requestPermission();
      Position geolocation = await Geolocator.getCurrentPosition();
      await placemarkFromCoordinates(geolocation.latitude, geolocation.longitude)
          .then((List<Placemark> placemarks) {
        Placemark place = placemarks[0];
        updateValue("currentCity", place.subAdministrativeArea!);
        updateValue("currentCountry", place.country!);
      });
      Response response = await Dio().get(
          "https://api.aladhan.com/v1/calendar/${dateTime.year}/${dateTime.month}?latitude=${geolocation.latitude}&longitude=${geolocation.longitude}");
      updateValue("prayerTimes/${dateTime.year}/${dateTime.month}", response.data);
    }
    prayerTimes = getValue("prayerTimes/${dateTime.year}/${dateTime.month}");
    final currentDateTime = DateTime.now();
    final currentFormattedTime = DateFormat('HH:mm').format(currentDateTime.toUtc());
    // setAllarmsForTheMonth();
    var prayerTimings = prayerTimes["data"][dateTime.day]["timings"];
    for (var prayer in prayerTimings.keys) {
      if (currentFormattedTime.compareTo(prayerTimings[prayer]!) < 0) {
        nextPrayer = prayer;
        nextPrayerTime = prayerTimings[prayer]!;
        break;
      }
    }

    if (nextPrayer.isEmpty ||
        nextPrayer == "Imsak" ||
        nextPrayer == "Firstthird" ||
        nextPrayer == "Midnight" ||
        nextPrayer == "Lastthird") {
      nextPrayer = 'Fajr';
      nextPrayerTime = prayerTimings['Fajr']!;
    }
    print("nextPrayer: $nextPrayer");
    print("nextPrayerTime: $nextPrayerTime");

    setState(() {
      isLoading = false;
    });
    setAllarmsForTheMonth();
    print(nextPrayer);
  }

  setAllarmsForTheMonth() async {
    await Future.delayed(const Duration(seconds: 1));
    // Loop through each data entry
    for (var entry in prayerTimes["data"]) {
      var dateInfo = entry["date"];
      var gregorianDate = dateInfo["gregorian"];
      var timings = entry["timings"];

      // Specify the prayer times you want to use
      var prayerTimesToUse = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];

      // Filter out unwanted prayer times
      var filteredTimings = timings.entries.where((entry) => prayerTimesToUse.contains(entry.key));

      // Loop through each filtered prayer time
      for (var prayerEntry in filteredTimings) {
        var prayer = prayerEntry.key;
        var time = prayerEntry.value;
        print("prayer time: " + time);
        print("prayer" + prayer);
        // Parse the time string
        var timeComponents = time.split(' ')[0].split(':');
        var hour = int.parse(timeComponents[0]);
        var minute = int.parse(timeComponents[1].split(' ')[0]);

        // Create the DateTime object using the date and time information
        var prayerDateTime = DateTime.utc(
          int.parse(gregorianDate["year"]),
          gregorianDate["month"]["number"],
          int.parse(gregorianDate["day"]),
          hour,
          minute,
        );

        if (prayerDateTime.isBefore(DateTime.now())) {
        } else {}
      }
    }
    getAlarms();
    final currentDateTime = DateTime.now();
    final nextPrayerTim = DateTime.parse(
        "${DateFormat('yyyy-MM-dd').format(currentDateTime)} ${nextPrayerTime.split(' ')[0]}");

    prayerTimes = getValue("prayerTimes/${dateTime.year}/${dateTime.month}");
    for (var i = dateTime.day; i < prayerTimes["data"].length; i++) {
      var prayerTimings = prayerTimes["data"][i]["timings"];
    }
  }

  String nextPrayer = '';
  String nextPrayerTime = '';
  int index = 0;
  void _updateTimeLeft() {
    final currentDateTime = DateTime.now();
    final nextPrayerTim = DateTime.parse(
        "${DateFormat('yyyy-MM-dd').format(currentDateTime)} ${nextPrayerTime.split(' ')[0]}");
    if (nextPrayer == "Fajr") {
      if (currentDateTime.isAfter(nextPrayerTim)) {
        final currentDateTime2 = DateTime.now();
        final nextPrayerTim2 = DateTime.parse(
                "${DateFormat('yyyy-MM-dd').format(currentDateTime)} ${nextPrayerTime.split(' ')[0]}")
            .add(const Duration(days: 1));
        final timeLeft = nextPrayerTim2.difference(currentDateTime2);
        _timeLeftController.add(timeLeft);
      } else {
        if (currentDateTime.isBefore(nextPrayerTim)) {
          final timeLeft = nextPrayerTim.difference(currentDateTime);
          _timeLeftController.add(timeLeft);
        }
      }
    } else {
      if (currentDateTime.isBefore(nextPrayerTim)) {
        final timeLeft = nextPrayerTim.difference(currentDateTime);
        _timeLeftController.add(timeLeft);
      }
    }
  }

  List prayers = [
    ["Fajr", "الفجر"],
    ["Sunrise", "الشروق"],
    ["Dhuhr", "الظهر"],
    ["Asr", "العصر"],
    ["Maghrib", "المغرب"],
    ["Isha", "العشاء"]
  ];
  getLocationData() {}
  String currentCity = "";

  String currentCountry = "";
  getAlarms() async {}

  updateDateData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    HijriCalendar.setLocal(context.locale.languageCode == "ar" ? "ar" : "en");
    _today = HijriCalendar.now();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: Navigator(
            onGenerateRoute: ((settings) => MaterialPageRoute(
                settings: settings,
                builder: (builder) => Scaffold(
                      backgroundColor: isDarkModeNotifier.value
                          ? darkModeSecondaryColor.withOpacity(0.7)
                          : quranPagesColorLight,
                      appBar: AppBar(
                        backgroundColor: isDarkModeNotifier.value
                            ? quranPagesColorDark.withOpacity(0.5)
                            : quranPagesColorLight,
                        centerTitle: true,
                        title: Text(
                          'main'.tr(),
                          style: TextStyle(
                              color: isDarkModeNotifier.value ? backgroundColor : Colors.black,
                              fontFamily: "cairo",
                              fontSize: 32.sp),
                        ),
                        leading: IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: isDarkModeNotifier.value ? Colors.white70 : Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(context,
                                CupertinoPageRoute(builder: (builder) => const SettingsView()));
                          },
                        ),
                      ),
                      body: SizedBox(
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
                                  // ignore:
                                  if (_today != null)
                                    SizedBox(
                                      // height: 55.h,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            height: 20.h,
                                          ),
                                          Text(
                                            _today.toFormat(
                                              "dd - MMMM - yyyy",
                                            ),
                                            style: TextStyle(
                                                color: isDarkModeNotifier.value
                                                    ? Colors.white70
                                                    : Colors.black,
                                                fontSize: 18.sp),
                                          ),
                                          Text(
                                            DateFormat.yMMMEd(context.locale.languageCode)
                                                .format(DateTime.now()),
                                            style: TextStyle(
                                                color: isDarkModeNotifier.value
                                                    ? Colors.white70
                                                    : Colors.black,
                                                fontSize: 18.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(height: 10.h),
                                  CustomListCardsHomeView(context, screenSize),
                                  SizedBox(height: 10.h),
                                ],
                              ),
                            ),
                          ][index],
                        ),
                      ),
                    )))));
  }

  Padding CustomListCardsHomeView(BuildContext context, Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.0.w),
      child: SizedBox(
        // height: screenSize.height * .5,
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SuperellipseButton(
                text: "quran".tr(),
                onPressed: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (builder) => SurahListPage(
                                jsonData: widgejsonData,
                                quarterjsonData: quarterjsonData,
                              )));
                },
                imagePath: isDarkModeNotifier.value
                    ? "assets/images/wqlogo.png"
                    : "assets/images/qlogo.png"),
            GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 2,
                mainAxisSpacing: 4,
                crossAxisCount: 2,
                children: <Widget>[
                  SuperellipseButton(
                      text: "Hadith".tr(),
                      onPressed: () {
                        // SystemChrome.setEnabledSystemUIMode(
                        //     SystemUiMode.immersiveSticky);
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (builder) => BlocProvider(
                                      create: (context) => hadithPageBloc,
                                      child: HadithBooksPage(locale: context.locale.languageCode),
                                    )));
                      },
                      imagePath: isDarkModeNotifier.value
                          ? "assets/images/wmuhammed.png"
                          : "assets/images/muhammed.png"),
                  SuperellipseButton(
                      text: "audios".tr(),
                      onPressed: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (builder) => BlocProvider(
                                      create: (create) => playerPageBloc,
                                      child: RecitersPage(
                                        jsonData: widgejsonData,
                                      ),
                                    )));
                      },
                      imagePath: isDarkModeNotifier.value
                          ? "assets/images/wquranlogo.png"
                          : "assets/images/quranlogo.png"),

                  SuperellipseButton(
                      text: "asmaa".tr(),
                      onPressed: () {
                        Navigator.push(
                            context, CupertinoPageRoute(builder: (c) => const AllahNamesPage()));
                      },
                      imagePath: isDarkModeNotifier.value
                          ? "assets/images/wnames.png"
                          : "assets/images/names.png"),
                  SuperellipseButton(
                      text: "azkar".tr(),
                      onPressed: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: ((context) => const AzkarHomePage())));
                        //boxController.openBox();
                      },
                      imagePath: isDarkModeNotifier.value
                          ? "assets/images/wazkar.png"
                          : "assets/images/azkar.png"),

                  SuperellipseButton(
                      text: "sibha".tr(),
                      onPressed: () async {
                        Navigator.push(
                            context, CupertinoPageRoute(builder: (builder) => const SibhaPage()));
                      },
                      imagePath: isDarkModeNotifier.value
                          ? "assets/images/wsibha.png"
                          : "assets/images/sibha.png"),
                  SuperellipseButton(
                      text: "calender".tr(),
                      onPressed: () async {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (builder) => const CalenderPage()));
                      },
                      imagePath: isDarkModeNotifier.value
                          ? "assets/images/wcalender.png"
                          : "assets/images/calender.png"),
                  // SuperellipseButton(
                  //     text: "qibla".tr(),
                  //     onPressed: () {
                  //       Navigator.push(context,
                  //           CupertinoPageRoute(builder: (builder) => const CompassWithQibla()));
                  //     },
                  //     imagePath: "assets/images/kabaa.png"),
                  SuperellipseButton(
                      text: "notifications".tr(),
                      onPressed: () async {
                        // await FlutterOverlayWindow.requestPermission();
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (builder) => const NotificationsPage()));
                      },
                      imagePath: "assets/images/notifications.png"),
                  // SuperellipseButton(
                  //     text: "livetv".tr(),
                  //     onPressed: () async {
                  //       Navigator.push(
                  //           context,
                  //           CupertinoPageRoute(
                  //               builder: (builder) =>
                  //                   const LiveTvPage()));
                  //     },
                  //     imagePath: "assets/images/tv.png"),
                  // SuperellipseButton(
                  //     text: "radios".tr(),
                  //     onPressed: () {
                  //       Navigator.push(
                  //           context,
                  //           CupertinoPageRoute(
                  //               builder: (builder) =>
                  //                   const RadioPage()));
                  //     },
                  //     imagePath:
                  //         "assets/images/radio.png"),
                  //         SuperellipseButton(
                  // text: "Short Videos".tr(),
                  // onPressed: () {
                  //   Navigator.push(
                  //       context,
                  //       CupertinoPageRoute(
                  //           builder: (builder) =>
                  //               const ContentScreen()));
                  // },
                  // imagePath: "assets/images/play.png"),
                ]),
            wedgitAya(context, screenSize),
            wedgitHadith(screenSize),
          ],
        ),
      ),
    );
  }

  Directionality wedgitHadith(Size screenSize) {
    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 6.h),
        child: Material(
          color: isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.2) : Colors.white,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(40.0.r),
          ),
          child:
              // AnimatedOpacity(
              // duration: const Duration(milliseconds: 500),
              // opacity: dominantColor != null ? 1.0 : 0,
              // child:
              suranumber != null
                  ? Padding(
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
                              SizedBox(
                                height: 10.h,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration:
                                        BoxDecoration(shape: BoxShape.circle, color: orangeColor),
                                    child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            indexOfHadith = Random().nextInt(hadithes.length);
                                          });
                                        },
                                        icon: Icon(
                                          Iconsax.refresh,
                                          color: Colors.white,
                                          size: 18.sp,
                                        )),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isDarkModeNotifier.value ? orangeColor : blueColor),
                                      child: IconButton(
                                          onPressed: () {
                                            Share.share(hadithes[indexOfHadith]["hadith"]);
                                          },
                                          icon: Icon(Iconsax.clipboard,
                                              color: Colors.white, size: 18.sp)))
                                ],
                              ),
                              SizedBox(
                                height: 10.h,
                              ),
                              SizedBox(
                                width: screenSize.width * .8,
                                child: Text(
                                  hadithes[indexOfHadith]["hadith"],
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: isDarkModeNotifier.value
                                          ? Colors.white70
                                          : goldColor, //fontWeight: FontWeight.bold,
                                      fontSize: 17.sp,
                                      fontFamily: "Taha"),
                                ),
                              ),
                              SizedBox(
                                height: 10.h,
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(),
        ),
      ),
    );
  }

  Directionality wedgitAya(BuildContext context, Size screenSize) {
    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 6.h),
        child: Material(
          color: isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.2) : Colors.white,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(40.0.r),
          ),
          child:
              // AnimatedOpacity(
              // duration: const Duration(milliseconds: 500),
              // opacity: dominantColor != null ? 1.0 : 0,
              // child:
              suranumber != null
                  ? Padding(
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
                              SizedBox(
                                height: 10.h,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration:
                                        BoxDecoration(shape: BoxShape.circle, color: orangeColor),
                                    child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            suranumber = Random().nextInt(114) + 1;
                                            verseNumber =
                                                Random().nextInt(getVerseCount(suranumber)) + 1;
                                          });
                                        },
                                        icon: Icon(
                                          Iconsax.refresh,
                                          color: Colors.white,
                                          size: 18.sp,
                                        )),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isDarkModeNotifier.value ? orangeColor : blueColor),
                                      child: IconButton(
                                          onPressed: () {
                                            showModalBottomSheet(
                                                backgroundColor: Colors.transparent,
                                                elevation: 0,
                                                context: context,
                                                builder: (ctx) => Container(
                                                      decoration: const BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.only(
                                                              topLeft: Radius.circular(12),
                                                              topRight: Radius.circular(12))),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          SizedBox(
                                                            height: 15.h,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceAround,
                                                            children: [
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                    color: quranPagesColorDark,
                                                                    borderRadius:
                                                                        BorderRadius.circular(12)),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.all(0.0),
                                                                  child: TextButton(
                                                                      onPressed: () {
                                                                        Navigator.push(
                                                                            context,
                                                                            CupertinoPageRoute(
                                                                                builder: (builder) =>
                                                                                    ScreenShotPreviewPage(
                                                                                        isQCF: true,
                                                                                        index: 5,
                                                                                        surahNumber:
                                                                                            suranumber,
                                                                                        jsonData:
                                                                                            widgejsonData,
                                                                                        firstVerse:
                                                                                            verseNumber,
                                                                                        lastVerse:
                                                                                            verseNumber)));
                                                                      },
                                                                      child: Text(
                                                                        "asimage".tr(),
                                                                        style: TextStyle(
                                                                            color: Colors.white,
                                                                            fontSize: 14.sp),
                                                                      )),
                                                                ),
                                                              ),
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                    color: quranPagesColorDark,
                                                                    borderRadius:
                                                                        BorderRadius.circular(12)),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.all(0.0),
                                                                  child: TextButton(
                                                                      onPressed: () {
                                                                        var verse = getVerse(
                                                                            suranumber, verseNumber,
                                                                            verseEndSymbol: true);
                                                                        var suraName =
                                                                            getSurahNameArabic(
                                                                                suranumber);
                                                                        Share.share(
                                                                            "$verse \nسورة $suraName");
                                                                      },
                                                                      child: Text(
                                                                        "astext".tr(),
                                                                        style: TextStyle(
                                                                            color: Colors.white,
                                                                            fontSize: 14.sp),
                                                                      )),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            height: 30.h,
                                                          )
                                                        ],
                                                      ),
                                                    ));
                                          },
                                          icon: Icon(Iconsax.share,
                                              color: Colors.white, size: 18.sp)))
                                ],
                              ),
                              SizedBox(
                                height: 20.h,
                              ),
                              SizedBox(
                                width: screenSize.width * .8,
                                child: Text(
                                  getVerse(
                                    suranumber,
                                    verseNumber,
                                  ),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: isDarkModeNotifier.value ? Colors.white70 : goldColor,
                                      fontSize: 22.sp, //fontWeight: FontWeight.w500,
                                      fontFamily: "UthmanicHafs13"),
                                ),
                              ),
                              Row(
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
                                      widgejsonData[suranumber - 1]["name"]
                                      // getSurahNameArabic(
                                      // ),
                                      ,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: fontFamilies[0],
                                        color:
                                            isDarkModeNotifier.value ? Colors.white70 : blueColor,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(
                                height: 10.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(),
        ),
      ),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {}

  @override
  bool get wantKeepAlive => true;
}
