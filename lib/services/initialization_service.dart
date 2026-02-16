// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ghaith/helpers/hive_initialization_example.dart';
import 'package:ghaith/services/display_service.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/blocs/observer.dart';
import 'package:ghaith/services/notification_service.dart' hide initializeNotificationDefaults;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:workmanager/workmanager.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeDependencies();
  await _configureSystemSettings();
  await _initializeWorkManager();
  await initializeNotificationDefaults();
}

// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
Future<void> _initializeDependencies() async {
  await ez.EasyLocalization.ensureInitialized();
  tz.initializeTimeZones();
  // Don't duplicate initialization
  // Don't duplicate initialization
  try {
    String timeZoneId = 'Africa/Cairo'; // Default fallback
    try {
      final dynamic timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      print("Timezone Type: ${timeZoneInfo.runtimeType}");
      print("Timezone Value: $timeZoneInfo");

      print('Time : ${DateTime.now()}');

      // 1. Try to get string directly if it is one
      if (timeZoneInfo is String && timeZoneInfo.isNotEmpty) {
        timeZoneId = timeZoneInfo;
      }
      // 2. Try to get .id property if it exists (dynamic access)
      else {
        try {
          final dynamic id = (timeZoneInfo as dynamic).id;
          if (id is String && id.isNotEmpty) {
            timeZoneId = id;
          }
        } catch (_) {}
      }

      // 3. Fallback to parsing toString() IF logic above failed and we are sure it's the custom object
      // But in release mode toString() might be "TimezoneInfo" only.
      // So if ID is still default or invalid, we try platform channel directly as a last resort.
    } catch (e) {
      print("❌ Error fetching timezone properly: $e");
    }

    // Double check if valid IANA ID (simple check)
    try {
      tz.getLocation(timeZoneId);
    } catch (_) {
      // If 'TimezoneInfo' or invalid string, fallback to Cairo or UTC
      print("⚠️ Invalid timezone ID '$timeZoneId', falling back to Africa/Cairo");
      timeZoneId = 'Africa/Cairo';
    }

    tz.setLocalLocation(tz.getLocation(timeZoneId));
    print("✅ Local location set to: $timeZoneId");
  } catch (e) {
    print("❌ Failed to set local location: $e");
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

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

  await setOptimalDisplayMode();
}

// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
Future<void> _initializeWorkManager() async {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  Bloc.observer = SimpleBlocObserver();
}
