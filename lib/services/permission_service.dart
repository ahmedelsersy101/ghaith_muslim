import 'package:permission_handler/permission_handler.dart';

Future<void> checkNotificationPermission() async {
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
