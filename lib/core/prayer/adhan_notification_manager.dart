import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ghaith/helpers/messaging_helper.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Global Adhan notification + audio manager.
///
/// Responsibilities:
/// - Manages a single looping Adhan audio player
/// - Shows a high-priority, persistent notification with a "Close" action
/// - Cleans up audio + notification on stop/replace
class AdhanNotificationManager {
  static const int _adhanNotificationId = 888;
  static const String _adhanChannelId = 'adhan_playback_channel';

  static AudioPlayer? _player;
  static bool _channelsInitialized = false;

  /// Initialize Android notification channel(s) for Adhan playback.
  ///
  /// Should be called once during app startup (e.g. in initialization_service).
  static Future<void> initializeChannels() async {
    if (_channelsInitialized) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _adhanChannelId,
        'Adhan Playback',
        description: 'Foreground notification for Adhan playback',
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
      );

      await androidPlugin.createNotificationChannel(channel);
    }

    _channelsInitialized = true;
  }

  /// Show Adhan notification and start looping Adhan audio.
  ///
  /// [prayerName] is used for the notification title.
  /// [adhanAudioPath] is the file name inside `assets/audio/adhan/`.
  static Future<void> showAdhanNotification({
    required String prayerName,
    required String adhanAudioPath,
  }) async {
    await initializeChannels();
    await _stopInternal();

    // Silence option: do not play Adhan if selected sound is "silence".
    if (adhanAudioPath == 'silence.ogg') {
      return;
    }

    final player = AudioPlayer();
    _player = player;

    try {
      await player.setLoopMode(LoopMode.one);
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse('asset:///assets/audio/adhan/$adhanAudioPath'),
          tag: MediaItem(
            id: adhanAudioPath,
            title: prayerName,
            artist: 'Adhan',
          ),
        ),
      );

      // Start playback without awaiting completion (looping).
      unawaited(player.play());
    } catch (e) {
      await _stopInternal();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _adhanChannelId,
      'Adhan Playback',
      channelDescription: 'Adhan is currently playing',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.service,
      fullScreenIntent: true,
      actions: [
        AndroidNotificationAction(
          'stop_adhan',
          'إيقاف الأذان',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    await flutterLocalNotificationsPlugin.show(
      _adhanNotificationId,
      'حان وقت صلاة $prayerName',
      'اضغط على إيقاف لإيقاف الأذان.',
      const NotificationDetails(
        android: androidDetails,
      ),
      payload: 'adhan:$prayerName',
    );
  }

  /// Stop Adhan audio and dismiss the notification.
  static Future<void> stopAdhan() async {
    await _stopInternal();
    await flutterLocalNotificationsPlugin.cancel(_adhanNotificationId);
  }

  /// Replace current Adhan with the next prayer (stop old, start new).
  static Future<void> replaceWithNextPrayer({
    required String prayerName,
    required String adhanAudioPath,
  }) async {
    await showAdhanNotification(
      prayerName: prayerName,
      adhanAudioPath: adhanAudioPath,
    );
  }

  /// Handle notification action callbacks (wired from NotificationService).
  static Future<void> onActionReceived(String actionId) async {
    if (actionId == 'stop_adhan') {
      await stopAdhan();
    }
  }

  static Future<void> _stopInternal() async {
    final player = _player;
    if (player == null) return;

    try {
      await player.stop();
      await player.dispose();
    } catch (_) {
      // Ignore errors during teardown.
    } finally {
      _player = null;
    }
  }
}
