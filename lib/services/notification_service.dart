import 'dart:io';
import 'dart:math';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notificationPlugin;
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/messaging_helper.dart';
import 'package:ghaith/core/notifications/data/40hadith.dart';
import 'package:ghaith/core/azkar/views/azkar_homepage.dart';
import 'package:ghaith/core/QuranPages/views/quranDetailsPage.dart';
import 'package:quran/quran.dart';
import 'package:ghaith/core/prayer/adhan_notification_manager.dart';
import 'package:workmanager/workmanager.dart';

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
    // ⭐ تحديث: تغيير معالج الصلاة على النبي
    case "sallahNotification":
    case "sallahNotificationTest":
      await _handleSallahNotification();
      break;
    // ⭐ جديد: معالجات الإشعارات الجديدة
    case "quranDailyReading":
    case "quranDailyReadingTest":
      await _handleQuranDailyReadingNotification();
      break;
    case "morningAzkar":
    case "morningAzkarTest":
      await _handleMorningAzkarNotification();
      break;
    case "eveningAzkar":
    case "eveningAzkarTest":
      await _handleEveningAzkarNotification();
      break;
  }
}

// [CAN_BE_EXTRACTED] -> services/notification_service.dart
Future<void> _handleZikrOverlayNotification() async {
  if (await overlay.FlutterOverlayWindow.isActive()) {
    overlay.FlutterOverlayWindow.closeOverlay();
  }

  await overlay.FlutterOverlayWindow.showOverlay(
    enableDrag: true,
    overlayTitle: "Zikr Notification",
    alignment: overlay.OverlayAlignment.center,
    overlayContent: 'Overlay Enabled',
    flag: overlay.OverlayFlag.defaultFlag,
    visibility: overlay.NotificationVisibility.visibilityPublic,
    positionGravity: overlay.PositionGravity.auto,
    height: 400,
    width: overlay.WindowSize.matchParent,
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

// ⭐ تحديث: تغيير الصلاة على النبي من ongoing إلى إشعار عادي دوري
Future<void> _handleSallahNotification() async {
  const notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.white,
      colorized: true,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        "اللهم صلِّ وسلم وبارك على نبينا محمد ﷺ\n\n"
        "قال رسول الله ﷺ: \"من صلى عليّ صلاة صلى الله عليه بها عشراً\"",
        contentTitle: "الصلاة على النبي ﷺ",
        htmlFormatBigText: true,
      ),
      "channelId3",
      importance: notificationPlugin.Importance.max,
      groupKey: "sallah",
      "Sally",
      icon: '@mipmap/ic_launcher',
    ),
  );

  await flutterLocalNotificationsPlugin.show(
    4,
    "صلِّ على النبي ﷺ",
    "اللهم صلِّ وسلم وبارك على نبينا محمد",
    notificationDetails,
  );
}

// ⭐ جديد: إشعار الورد القرآني اليومي
Future<void> _handleQuranDailyReadingNotification() async {
  const notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.white,
      colorized: true,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        "حان وقت قراءة وردك اليومي من القرآن الكريم 📖\n\n"
        "\"إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ\"\n"
        "[فاطر: 29]",
        contentTitle: "⏰ الورد القرآني",
        htmlFormatBigText: true,
      ),
      "channelId4",
      importance: notificationPlugin.Importance.max,
      groupKey: "quranDaily",
      "Quran Daily Reading",
      icon: '@mipmap/ic_launcher',
      priority: notificationPlugin.Priority.high,
    ),
  );

  await flutterLocalNotificationsPlugin.show(
    5,
    "⏰ تذكير بالورد القرآني",
    "حان وقت قراءة وردك من القرآن الكريم",
    notificationDetails,
    payload: 'quranDaily', // ⭐ جديد: إضافة payload للتنقل
  );
}

// ⭐ جديد: إشعار أذكار الصباح
Future<void> _handleMorningAzkarNotification() async {
  final morningAzkar = [
    "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ",
    "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ",
    "أَصْبَحْنَا عَلَى فِطْرَةِ الإِسْلَامِ، وَعَلَى كَلِمَةِ الإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ",
  ];

  final randomZikr = morningAzkar[Random().nextInt(morningAzkar.length)];

  final notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.amber,
      colorized: true,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        randomZikr,
        contentTitle: "🌅 أذكار الصباح",
        htmlFormatBigText: true,
      ),
      "channelId5",
      importance: notificationPlugin.Importance.max,
      groupKey: "morningAzkar",
      "Morning Azkar",
      icon: '@mipmap/ic_launcher',
      priority: notificationPlugin.Priority.high,
    ),
  );

  await flutterLocalNotificationsPlugin.show(
    6,
    "🌅 أذكار الصباح",
    "حان وقت أذكار الصباح",
    notificationDetails,
    payload: 'morningAzkar', // ⭐ جديد: إضافة payload للتنقل
  );
}

// ⭐ جديد: إشعار أذكار المساء
Future<void> _handleEveningAzkarNotification() async {
  final eveningAzkar = [
    "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ",
    "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ",
    "أَمْسَيْنَا عَلَى فِطْرَةِ الإِسْلَامِ، وَعَلَى كَلِمَةِ الإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ",
  ];

  final randomZikr = eveningAzkar[Random().nextInt(eveningAzkar.length)];

  final notificationDetails = notificationPlugin.NotificationDetails(
    android: notificationPlugin.AndroidNotificationDetails(
      color: Colors.deepPurple,
      colorized: true,
      styleInformation: notificationPlugin.BigTextStyleInformation(
        randomZikr,
        contentTitle: "🌙 أذكار المساء",
        htmlFormatBigText: true,
      ),
      "channelId6",
      importance: notificationPlugin.Importance.max,
      groupKey: "eveningAzkar",
      "Evening Azkar",
      icon: '@mipmap/ic_launcher',
      priority: notificationPlugin.Priority.high,
    ),
  );

  await flutterLocalNotificationsPlugin.show(
    7,
    "🌙 أذكار المساء",
    "حان وقت أذكار المساء",
    notificationDetails,
    payload: 'eveningAzkar', // ⭐ جديد: إضافة payload للتنقل
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  // ⭐ جديد: GlobalKey للتنقل من خارج BuildContext
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initializeNotifications();
  }

  // ⭐ جديد: تهيئة الإشعارات مع معالج النقرات
  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        notificationPlugin.AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = notificationPlugin.InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // ⭐ جديد: معالج النقرات على الإشعارات
  void _onNotificationTapped(notificationPlugin.NotificationResponse response) {
    // First, handle any Adhan-specific actions (e.g., "stop_adhan").
    final actionId = response.actionId;
    if (actionId != null && actionId == 'stop_adhan') {
      AdhanNotificationManager.onActionReceived(actionId);
      return;
    }

    final payload = response.payload;
    if (payload == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // التنقل بناءً على نوع الإشعار
    switch (payload) {
      case 'morningAzkar':
      case 'eveningAzkar':
        // فتح صفحة الأذكار
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AzkarHomePage(),
          ),
        );
        break;
      case 'quranDaily':
        // فتح صفحة القرآن
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuranReadingPage(),
          ),
        );
        break;
    }
  }

  /// عرض إشعار فوري (للاختبار)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationPlugin.NotificationDetails(
        android: notificationPlugin.AndroidNotificationDetails(
          channelId,
          channelName,
          importance: notificationPlugin.Importance.max,
          priority: notificationPlugin.Priority.high,
        ),
      ),
    );
  }

  // Add channel creation logic for new channels (4, 5, etc) if missing, or update existing ones.
  Future<void> initializeNotificationChannels() async {
    const notificationPlugin.AndroidNotificationChannel channel =
        notificationPlugin.AndroidNotificationChannel(
      'channelId', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: notificationPlugin.Importance.max,
    );

    const notificationPlugin.AndroidNotificationChannel channel2 =
        notificationPlugin.AndroidNotificationChannel(
      'channelId2', // id
      'Zikr Notifications', // title
      description: 'This channel is used for Zikr notifications.', // description
      importance: notificationPlugin.Importance.max,
    );

    // ⭐ جديد: قنوات إضافية لباقي الإشعارات
    const notificationPlugin.AndroidNotificationChannel channel3 =
        notificationPlugin.AndroidNotificationChannel(
      'channelId3', // id
      'Sally Notifications', // title
      description: 'This channel is used for Sally notifications.', // description
      importance: notificationPlugin.Importance.max,
    );

    const notificationPlugin.AndroidNotificationChannel channel4 =
        notificationPlugin.AndroidNotificationChannel(
      'channelId4', // id
      'Quran Daily Notifications', // title
      description: 'This channel is used for Quran Daily notifications.', // description
      importance: notificationPlugin.Importance.max,
    );

    const notificationPlugin.AndroidNotificationChannel channel5 =
        notificationPlugin.AndroidNotificationChannel(
      'channelId5', // id
      'Morning Azkar Notifications', // title
      description: 'This channel is used for Morning Azkar notifications.', // description
      importance: notificationPlugin.Importance.max,
    );

    const notificationPlugin.AndroidNotificationChannel channel6 =
        notificationPlugin.AndroidNotificationChannel(
      'channelId6', // id
      'Evening Azkar Notifications', // title
      description: 'This channel is used for Evening Azkar notifications.', // description
      importance: notificationPlugin.Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notificationPlugin.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notificationPlugin.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel2);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notificationPlugin.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel3);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notificationPlugin.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel4);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notificationPlugin.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel5);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            notificationPlugin.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel6);
  }

  /// جدولة إشعار يومي في وقت محدد
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String channelId,
    required String channelName,
    String? payload, // ⭐ جديد: إضافة payload اختياري
  }) async {
    try {
      print("🔔 Requesting permissions on Android...");
      bool? grantedExactAlarm = true; // Default to true for non-Android or if not explicitly denied
      if (Platform.isAndroid) {
        final platformImplementation =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                notificationPlugin.AndroidFlutterLocalNotificationsPlugin>();

        await platformImplementation?.requestNotificationsPermission();

        // Request Exact Alarm permission for Android 12+
        grantedExactAlarm = await platformImplementation?.requestExactAlarmsPermission();
        print("🔔 Exact Alarm Permission Status: $grantedExactAlarm");
      }

      if (grantedExactAlarm == false) {
        print("❌ Exact alarm permission denied! Notification might be inexact or delayed.");
      }

      final scheduledDate = _nextInstanceOfTime(time);
      print("📅 Scheduling notification ID:$id for: $scheduledDate (Local Time)");
      print("ℹ️ Current Time: ${tz.TZDateTime.now(tz.local)}");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationPlugin.NotificationDetails(
          android: notificationPlugin.AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Daily reminders for Azkar and Quran',
            importance: notificationPlugin.Importance.max,
            priority: notificationPlugin.Priority.high,
          ),
        ),
        androidScheduleMode: notificationPlugin.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: notificationPlugin.DateTimeComponents.time,
        payload: payload, // ⭐ جديد: تمرير الـ payload
      );
      print("✅ Notification scheduled successfully: $id");
    } catch (e) {
      print("❌ Error scheduling notification: $e");
    }
  }

  /// إلغاء إشعار محدد
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("🗑️ Notification cancelled: $id");
  }

  /// حساب الوقت القادم للإشعار (مع مراعاة المنطقة الزمنية)
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

// This function is assumed to be the missing 'initializeNotificationDefaults' function
// that the user referred to. It initializes all channels.
Future<void> initializeNotificationDefaults() async {
  await NotificationService().initializeNotificationChannels();
}
