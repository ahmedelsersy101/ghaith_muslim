// [CAN_BE_EXTRACTED] -> services/initialization_service.dart
import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghaith/services/display_service.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/blocs/observer.dart';
import 'package:ghaith/services/notification_service.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:workmanager/workmanager.dart';

Future<void> initializeApp() async {
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
