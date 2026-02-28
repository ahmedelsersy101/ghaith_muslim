import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing prayer-related notifications
/// Handles Adhan notifications, reminders, and persistent notifications
class PrayerNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _prayerChannelId = 'prayer_times_channel';
  static const String _reminderChannelId = 'prayer_reminder_channel';
  static const String _persistentChannelId = 'prayer_persistent_channel';

  /// Initialize notification service
  Future<void> initialize() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permission
    await requestPermission();

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // Prayer time channel (Adhan)
    const prayerChannel = AndroidNotificationChannel(
      _prayerChannelId,
      'Prayer Times',
      description: 'Notifications for prayer times with Adhan',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    );

    // Reminder channel
    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Prayer Reminders',
      description: 'Reminder notifications before prayer times',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Persistent channel
    const persistentChannel = AndroidNotificationChannel(
      _persistentChannelId,
      'Next Prayer Countdown',
      description: 'Persistent notification showing next prayer time',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(prayerChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(persistentChannel);
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Schedule Adhan notification for a specific prayer
  Future<void> scheduleAdhanNotification({
    required int id,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    String? adhanSoundPath,
  }) async {
    // Check if notifications are enabled for this prayer
    final isEnabled = _isPrayerNotificationEnabled(prayerName);
    if (!isEnabled) return;

    final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
    // Format the prayer time as HH:mm
    final formattedTime =
        '${prayerTime.hour.toString().padLeft(2, '0')}:${prayerTime.minute.toString().padLeft(2, '0')}';

    const androidDetails = AndroidNotificationDetails(
      _prayerChannelId,
      'Prayer Times',
      channelDescription: 'Notifications for prayer times with Adhan',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      sound: null,
      enableVibration: true,
      fullScreenIntent: true,
      autoCancel: true,
      ongoing: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Notification body with prayer time
    final bodyText = 'It\'s time for $prayerName prayer at $formattedTime';

    await _notificationsPlugin.zonedSchedule(
      id,
      'حان وقت صلاة $prayerNameArabic - $formattedTime',
      bodyText,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Payload includes adhan sound so that future integrations
      // can trigger AdhanNotificationManager if needed.
      payload: adhanSoundPath != null ? 'prayer:$prayerName|$adhanSoundPath' : 'prayer:$prayerName',
    );
  }

  /// Schedule reminder notification before prayer time
  Future<void> scheduleReminderNotification({
    required int id,
    required String prayerName,
    required String prayerNameArabic,
    required DateTime prayerTime,
    required int minutesBefore,
  }) async {
    final reminderTime = prayerTime.subtract(Duration(minutes: minutesBefore));

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Prayer Reminders',
      channelDescription: 'Reminder notifications before prayer times',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      'تذكير بصلاة $prayerNameArabic',
      '$prayerName prayer in $minutesBefore minutes',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'reminder:$prayerName',
    );
  }

  /// Show persistent notification with next prayer countdown
  Future<void> showPersistentNotification({
    required String nextPrayer,
    required String timeRemaining,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _persistentChannelId,
      'Next Prayer Countdown',
      channelDescription: 'Persistent notification showing next prayer time',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      999, // Fixed ID for persistent notification
      'Next Prayer: $nextPrayer',
      'Time remaining: $timeRemaining',
      notificationDetails,
      payload: 'persistent',
    );
  }

  /// Cancel persistent notification
  Future<void> cancelPersistentNotification() async {
    await _notificationsPlugin.cancel(999);
  }

  /// Schedule all prayer notifications for the day
  Future<void> scheduleAllPrayersForDay(Map<String, DateTime> prayerTimes) async {
    // Cancel all previous prayer notifications to prevent duplicates
    await cancelAllPrayerNotifications();

    int notificationId = 1000; // Start from 1000 for prayer notifications

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prayersArabic = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    for (var prayer in prayers) {
      final prayerTime = prayerTimes[prayer.toLowerCase()];
      if (prayerTime != null && prayerTime.isAfter(DateTime.now())) {
        // Schedule main Adhan notification
        await scheduleAdhanNotification(
          id: notificationId++,
          prayerName: prayer,
          prayerNameArabic: prayersArabic[prayer]!,
          prayerTime: prayerTime,
          adhanSoundPath: _getSelectedAdhanSound(),
        );

        // Schedule reminder if enabled
        final reminderMinutes = _getReminderMinutes();
        if (reminderMinutes > 0) {
          await scheduleReminderNotification(
            id: notificationId++,
            prayerName: prayer,
            prayerNameArabic: prayersArabic[prayer]!,
            prayerTime: prayerTime,
            minutesBefore: reminderMinutes,
          );
        }
      }
    }
  }

  /// Cancel the main scheduled notification for a specific prayer (not the reminder).
  Future<void> cancelPrayerNotification(String prayerName) async {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final reminderMinutes = _getReminderMinutes();

    // Base ID logic must mirror scheduleAllPrayersForDay
    int baseId = 1000;

    final index = prayers.indexOf(prayerName);
    if (index == -1) return;

    int notificationId;
    if (reminderMinutes > 0) {
      // When reminders are enabled, each prayer consumes 2 IDs: main + reminder.
      notificationId = baseId + (index * 2);
    } else {
      // When reminders are disabled, each prayer consumes 1 ID.
      notificationId = baseId + index;
    }

    await _notificationsPlugin.cancel(notificationId);
  }

  /// Handle notification tap and action
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on payload
    final payload = response.payload;
    if (payload != null) {
      if (payload.startsWith('prayer:')) {
        // Navigate to prayer times page
      } else if (payload.startsWith('reminder:')) {
        // Navigate to prayer times page
      }
    }
  }

  /// Check if notification is enabled for a specific prayer
  bool _isPrayerNotificationEnabled(String prayerName) {
    final key = 'prayerNotificationEnabled_${prayerName.toLowerCase()}';
    return getValue(key) ?? true; // Default to enabled
  }

  /// Cancel all scheduled prayer notifications
  Future<void> cancelAllPrayerNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get selected Adhan sound path from settings
  String? _getSelectedAdhanSound() {
    return getValue('selectedAdhanSound') ?? 'aqsa_athan.ogg';
  }

  /// Get reminder minutes from settings
  int _getReminderMinutes() {
    return getValue('prayerReminderMinutes') ?? 0; // Default to 0 (disabled)
  }

  /// Update notification enabled status for a prayer
  Future<void> setPrayerNotificationEnabled(String prayerName, bool enabled) async {
    final key = 'prayerNotificationEnabled_${prayerName.toLowerCase()}';
    await updateValue(key, enabled);
  }

  /// Set Adhan sound
  Future<void> setAdhanSound(String soundPath) async {
    await updateValue('selectedAdhanSound', soundPath);
  }

  /// Set reminder minutes
  Future<void> setReminderMinutes(int minutes) async {
    await updateValue('prayerReminderMinutes', minutes);
  }

  /// Set persistent notification enabled
  Future<void> setPersistentNotificationEnabled(bool enabled) async {
    await updateValue('persistentPrayerNotification', enabled);
    if (!enabled) {
      await cancelPersistentNotification();
    }
  }

  /// Get persistent notification enabled status
  bool isPersistentNotificationEnabled() {
    return getValue('persistentPrayerNotification') ?? false;
  }
}
