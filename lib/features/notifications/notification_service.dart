import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Central hub for flutter_local_notifications.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  // Will be set by main.dart via GoRouter
  static void Function(String taskId)? onNotificationTapped;

  static Future<void> initialise() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.payload;
        if (taskId != null && onNotificationTapped != null) {
          onNotificationTapped!(taskId);
        }
      },
    );
  }

  static Future<void> requestPermissions() async {
    await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> cancelAll() => plugin.cancelAll();
  static Future<void> cancel(int id) => plugin.cancel(id);
}
