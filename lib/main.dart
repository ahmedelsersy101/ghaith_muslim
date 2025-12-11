import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
// ignore: library_prefixes
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    // ignore: library_prefixes
    as notificationPlugin;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:workmanager/workmanager.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/blocs/bloc/bloc/player_bar_bloc.dart';
import 'package:ghaith/blocs/bloc/player_bloc_bloc.dart';
import 'package:ghaith/blocs/bloc/quran_page_player_bloc.dart';
import 'package:ghaith/blocs/bloc/observer.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/GlobalHelpers/messaging_helper.dart';
import 'package:ghaith/core/home.dart';
import 'package:ghaith/core/notifications/data/40hadith.dart';
import 'package:ghaith/core/notifications/views/small_notification_popup.dart';
import 'package:ghaith/core/splash/splash_screen.dart';
import 'package:quran/quran.dart';

// =============================================
// 🎛️ GLOBAL VARIABLES & INITIALIZATION
// =============================================

// [CAN_BE_EXTRACTED] -> globals/app_globals.dart
final AudioPlayer audioPlayer = AudioPlayer();
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(getValue("darkMode") ?? false);

// =============================================
// 🚀 MAIN APPLICATION ENTRY POINT
// =============================================

void main() async {
  await _initializeApp();

  runApp(ez.EasyLocalization(
    supportedLocales: const [
      Locale("ar"),
      Locale('en'),
      Locale('de'),
      Locale("am"),
      Locale("ms"),
      Locale("pt"),
      Locale("tr"),
      Locale("ru")
    ],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar'),
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PlayerBlocBloc()),
        BlocProvider(create: (_) => QuranPagePlayerBloc()),
        BlocProvider(create: (_) => PlayerBarBloc()),
      ],
      child: const MyApp(),
    ),
  ));
}

// =============================================
// 🔧 INITIALIZATION METHODS - يمكن نقلها لملف initialization_service.dart
// =============================================

// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeDependencies();
  await _configureSystemSettings();
  await _initializeWorkManager();
}

// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
Future<void> _initializeDependencies() async {
  await ez.EasyLocalization.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yourapp.audio',
    androidNotificationChannelName: 'Quran Player',
    androidNotificationOngoing: true,
  );
  await initializeHive();
}

// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
Future<void> _configureSystemSettings() async {

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await _setOptimalDisplayMode();
}

// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
Future<void> _initializeWorkManager() async {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  Bloc.observer = SimpleBlocObserver();
}

// =============================================
// 🎯 DISPLAY OPTIMIZATION - يمكن نقلها لملف display_service.dart
// =============================================

// [CAN_BE_EXTRACTED] -> services/display_service.dart
Future<void> _setOptimalDisplayMode() async {
    if (!Platform.isAndroid) return; // البلجن Android فقط

  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution = supported
      .where((DisplayMode m) => m.width == active.width && m.height == active.height)
      .toList()
    ..sort((DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate));

  final DisplayMode mostOptimalMode = sameResolution.isNotEmpty ? sameResolution.first : active;

  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

// =============================================
// 🔔 OVERLAY ENTRY POINT - يمكن نقلها لملف overlay_service.dart
// =============================================

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrueCallerOverlay());
}

// =============================================
// 📱 BACKGROUND TASK HANDLER - يمكن نقلها لملف notification_service.dart
// =============================================

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    await _handleBackgroundTask(task);

    print("Native called background task: $task");
    return Future.value(true);
  });
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleBackgroundTask(String task) async {
  switch (task) {
    case "zikrNotification":
    case "zikrNotificationTest":
      await _handleZikrOverlayNotification();
      break;
    case "zikrNotification2":
    case "zikrNotificationTest2":
      await _handleZikrLocalNotification();
      break;
    case "ayahNot":
    case "ayahNotTest":
      await _handleAyahNotification();
      break;
    case "hadithNot":
    case "hadithNotTest":
      await _handleHadithNotification();
      break;
    case "sallahEnable":
      await _handleSalahNotification(true);
      break;
    case "sallahDisable":
      await _handleSalahNotification(false);
      break;
  }
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleZikrOverlayNotification() async {
  if (await FlutterOverlayWindow.isActive()) {
    FlutterOverlayWindow.closeOverlay();
  }

  await FlutterOverlayWindow.showOverlay(
    enableDrag: true,
    overlayTitle: "Zikr Notification",
    alignment: OverlayAlignment.center,
    overlayContent: 'Overlay Enabled',
    flag: OverlayFlag.defaultFlag,
    visibility: NotificationVisibility.visibilityPublic,
    positionGravity: PositionGravity.auto,
    height: 400,
    width: WindowSize.matchParent,
  );
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleZikrLocalNotification() async {
  final index = Random().nextInt(zikrNotfications.length);
  final notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.white,
      colorized: true,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        zikrNotfications[index],
        contentTitle: "Zikr",
        htmlFormatBigText: true,
      ),
      "channelId2",
      importance: notificationPlugin.Importance.max,
      groupKey: "zikr,",
      "Zikr",
      icon: '@mipmap/ic_launcher',
    ),
  );

  await flutterLocalNotificationsPlugin.show(2, zikrNotfications[index], "", notificationDetails);
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleAyahNotification() async {
  final suraNumber = Random().nextInt(114) + 1;
  final verseNumber = Random().nextInt(getVerseCount(suraNumber)) + 1;
  final verseText = getVerse(suraNumber, verseNumber);

  final notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.white,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        verseText,
        contentTitle: "Ayah",
        htmlFormatBigText: true,
      ),
      "channelId",
      importance: notificationPlugin.Importance.max,
      groupKey: "verses,",
      "verses",
      icon: '@mipmap/ic_launcher',
    ),
  );

  await flutterLocalNotificationsPlugin.show(1, verseText, "", notificationDetails);
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleHadithNotification() async {
  final index = Random().nextInt(42);
  final hadithText = hadithes[index]["hadith"];

  final notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.white,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        hadithText,
        contentTitle: "Hadith",
        htmlFormatBigText: true,
      ),
      "channelId",
      importance: notificationPlugin.Importance.max,
      groupKey: "vehadith,",
      "hadith",
      icon: '@mipmap/ic_launcher',
    ),
  );

  await flutterLocalNotificationsPlugin.show(3, hadithText, "", notificationDetails);
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleSalahNotification(bool enable) async {
  if (enable) {
    const notificationDetails = notificationPlugin.NotificationDetails(
      android: notificationPlugin.AndroidNotificationDetails(
        color: Colors.white,
        "channelId3",
        importance: notificationPlugin.Importance.max,
        groupKey: "sallah",
        "Sally",
        ongoing: true,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      3,
      "صلِّ على النبي ﷺ",
      "",
      notificationDetails,
    );
  } else {
    await flutterLocalNotificationsPlugin.cancel(3);
  }
}

// =============================================
// 🏗️ MAIN APPLICATION WIDGET
// =============================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// =============================================
// 🔧 MAIN APPLICATION STATE
// =============================================

class _MyAppState extends State<MyApp> {
  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _setupApp();
  }

  // =============================================
  // 🔧 SETUP METHODS - يمكن نقلها لملف app_service.dart
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/app_service.dart
  Future<void> _setupApp() async {
    // يمكن إضافة إعدادات إضافية هنا إذا لزم الأمر
  }

  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      builder: (context, child) => BlocProvider(
        create: (context) => playerbarBloc,
        child: ValueListenableBuilder(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'غيث المسلم',
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: _buildTheme(context, false),
              darkTheme: _buildTheme(context, true),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }

  // =============================================
  // 🎨 THEME BUILDER - يمكن نقلها لملف app_themes.dart
  // =============================================

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  ThemeData _buildTheme(BuildContext context, bool isDark) {
    final fontFamily = _getFontFamily(context);

    return isDark
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.blue,
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: fontFamily),
            primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(fontFamily: fontFamily),
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            textTheme: ThemeData.light().textTheme.apply(fontFamily: fontFamily),
            primaryTextTheme: ThemeData.light().primaryTextTheme.apply(fontFamily: fontFamily),
          );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  String _getFontFamily(BuildContext context) {
    return context.locale.languageCode == "ar" ? "cairo" : "roboto";
  }
}
