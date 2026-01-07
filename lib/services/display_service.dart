// [CAN_BE_EXTRACTED] -> services/display_service.dart
import 'dart:io';

import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> setOptimalDisplayMode() async {
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
