import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/initializeData.dart';
import 'package:ghaith/GlobalHelpers/messaging_helper.dart';
import 'package:ghaith/core/home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart' as ez;

// 🔹 [CAN_BE_EXTRACTED] يمكن نقل إدارة التخزين لملف services/storage_service.dart
final mediaStorePlugin = MediaStore();

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل قائمة الأذكار لملف constants/zikr_constants.dart
  static const List<String> zikrNotifs = [
    "صلي علي محمد ﷺ",
    "اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي",
    "لا حول ولا قوة الا بالله",
    "لا اله الا الله, محمد رسول الله",
    "لا اله الا انت سبحانك اني كنت من الظالمين",
    "استغفر الله",
    "سبحان الله",
    "الحمدلله",
    "لا اله الا الله",
    "الله اكبر"
  ];

  String _randomZikr = "";

  @override
  void initState() {
    _initializeSplash();
    super.initState();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل التهيئة لملف services/splash_initializer.dart
  void _initializeSplash() {
    _generateRandomZikr();
    initHiveValues();
    _checkNotificationPermission();
    _downloadAndStoreHadithData();
    _getAndStoreRecitersData();
    _initStoragePermission();
    _navigateToHome();
  }

  void _generateRandomZikr() {
    setState(() {
      _randomZikr = zikrNotifs[Random().nextInt(zikrNotifs.length)];
    });
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل إدارة الصلاحيات لملف services/permission_service.dart
  Future<void> _checkNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();

    print('Notification permission status: $status');

    if (status.isGranted) {
      print('Notification permission granted');
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else if (status.isDenied) {
      print('Notification permission denied');
    }
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل التنقل لملف services/navigation_service.dart
  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (builder) => const Home()),
        (route) => false,
      );
    }
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل بيانات القراء لملف services/reciters_service.dart
  Future<void> _getAndStoreRecitersData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final languageCode = _getLanguageCode();

    if (_shouldFetchRecitersData(prefs, languageCode)) {
      await _fetchAndStoreRecitersData(prefs, languageCode);
    }

    prefs.setInt("zikrNotificationindex", 0);
  }

  String _getLanguageCode() {
    final locale = context.locale.languageCode;
    if (locale == "ms") return "eng";
    return locale == "en" ? "eng" : locale;
  }

  bool _shouldFetchRecitersData(SharedPreferences prefs, String languageCode) {
    return prefs.getString("reciters-$languageCode") == null ||
        prefs.getString("moshaf-$languageCode") == null ||
        prefs.getString("suwar-$languageCode") == null;
  }

  Future<void> _fetchAndStoreRecitersData(SharedPreferences prefs, String languageCode) async {
    try {
      final responses = await Future.wait([
        _fetchRecitersData(languageCode),
        _fetchMoshafData(languageCode),
        _fetchSuwarData(languageCode),
      ]);

      await _storeRecitersData(prefs, languageCode, responses);
    } catch (error) {
      print('Error while storing reciters data: $error');
    }
  }

  Future<Response> _fetchRecitersData(String languageCode) {
    return Dio().get('http://mp3quran.net/api/v3/reciters?language=$languageCode');
  }

  Future<Response> _fetchMoshafData(String languageCode) {
    return Dio().get('http://mp3quran.net/api/v3/moshaf?language=$languageCode');
  }

  Future<Response> _fetchSuwarData(String languageCode) {
    return Dio().get('http://mp3quran.net/api/v3/suwar?language=$languageCode');
  }

  Future<void> _storeRecitersData(
      SharedPreferences prefs, String languageCode, List<Response> responses) async {
    if (responses[0].data != null) {
      final jsonData = json.encode(responses[0].data['reciters']);
      prefs.setString("reciters-$languageCode", jsonData);
    }

    if (responses[1].data != null) {
      final jsonData2 = json.encode(responses[1].data);
      prefs.setString("moshaf-$languageCode", jsonData2);
    }

    if (responses[2].data != null) {
      final jsonData3 = json.encode(responses[2].data['suwar']);
      prefs.setString("suwar-$languageCode", jsonData3);
    }
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل بيانات الحديث لملف services/hadith_service.dart
  Future<void> _downloadAndStoreHadithData() async {
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

// أضف هذه الدالة في نفس الملف أو في service منفصل
Future<void> setOptimalDisplayMode() async {
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution = supported
      .where((DisplayMode m) => m.width == active.width && m.height == active.height)
      .toList()
    ..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

  final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;
  
  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل إدارة التخزين لملف services/storage_service.dart
  Future<void> _initStoragePermission() async {
    List<Permission> permissions = [
      Permission.storage,
    ];

    if ((await mediaStorePlugin.getPlatformSDKInt()) >= 35) {
      permissions.addAll([
        Permission.photos,
        Permission.audio,
        Permission.location,
      ]);
    }

    await permissions.request();
    MediaStore.appFolder = "ghaith";
    initMessaging();
    setOptimalDisplayMode();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: quranPagesColorLight,
        body: _buildSplashContent(),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل واجهة المستخدم لملف ui/splash_screen.dart
  Widget _buildSplashContent() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildZikrText(),
              SizedBox(height: 16.h),
              _buildAppLogo(),
              _buildLoadingAnimation(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildZikrText() {
    return Text(
      _randomZikr,
      style: TextStyle(
        color: Colors.black,
        fontSize: 22.sp,
        fontFamily: fontFamilies[Random().nextInt(fontFamilies.length)],
      ),
    );
  }

  Widget _buildAppLogo() {
    return Image.asset(
      "assets/images/ghaith.png",
      height: 160,
      width: 160,
    );
  }

  Widget _buildLoadingAnimation() {
    return LottieBuilder.asset(
      "assets/images/loading.json",
      repeat: true,
      height: 80.h,
    );
  }
}
