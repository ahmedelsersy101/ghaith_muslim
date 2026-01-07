import 'dart:math';

import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notificationPlugin;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/messaging_helper.dart';
import 'package:ghaith/core/notifications/data/40hadith.dart';
import 'package:quran/quran.dart';
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
