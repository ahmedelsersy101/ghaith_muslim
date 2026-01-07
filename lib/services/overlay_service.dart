import 'package:flutter/material.dart';
import 'package:ghaith/core/notifications/views/small_notification_popup.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrueCallerOverlay());
}
