import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Platform-safe local notification service for BVCEC SmartQueue.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize local notification channels safely across supported platforms.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (!kIsWeb &&
          (Platform.isAndroid ||
              Platform.isIOS ||
              Platform.isMacOS ||
              Platform.isLinux)) {
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinSettings = DarwinInitializationSettings();
        const linuxSettings =
            LinuxInitializationSettings(defaultActionName: 'Open notification');

        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
          linux: linuxSettings,
        );

        await _localNotifications.initialize(initSettings);

        // Request permissions on Android 13+
        if (Platform.isAndroid) {
          final androidPlatform = _localNotifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
          await androidPlatform?.requestNotificationsPermission();
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (graceful fallback): $e');
    }
  }

  /// Show a system local notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!kIsWeb &&
          (Platform.isAndroid ||
              Platform.isIOS ||
              Platform.isMacOS ||
              Platform.isLinux)) {
        const androidDetails = AndroidNotificationDetails(
          'smartqueue_channel',
          'BVCEC SmartQueue Notifications',
          channelDescription:
              'Notifications for token calls, queue status, and wait times',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        );

        await _localNotifications.show(id, title, body, notificationDetails);
      }
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  /// Notify student when their token is called.
  Future<void> notifyTokenCalled({
    required int tokenNumber,
    required String? counterName,
  }) async {
    final destination = counterName != null
        ? 'Please proceed to $counterName.'
        : 'Please proceed to your counter.';
    await showNotification(
      id: tokenNumber,
      title: '🔔 Token #$tokenNumber Called!',
      body: destination,
    );
  }

  /// Notify student when their turn is approaching (e.g. 2nd in line).
  Future<void> notifyTurnApproaching({
    required int tokenNumber,
    required int position,
  }) async {
    await showNotification(
      id: tokenNumber + 10000,
      title: '⚠️ Your Turn Is Approaching!',
      body: 'Token #$tokenNumber is currently #$position in line. Please be ready.',
    );
  }
}
