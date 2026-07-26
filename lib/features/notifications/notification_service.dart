import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Central hub for awesome_notifications.
class NotificationService {
  NotificationService._();

  static final AwesomeNotifications plugin = AwesomeNotifications();

  // Will be set by main.dart via GoRouter
  static void Function(String taskId)? onNotificationTapped;

  static Future<void> initialise() async {
    await plugin.initialize(
      // Set the icon to null for using the default app icon
      null,
      [
        NotificationChannel(
          channelKey: 'taskstack_tasks',
          channelName: 'Task Reminders',
          channelDescription: 'Reminders for your scheduled tasks',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'taskstack_group',
          channelGroupName: 'TaskStack Notifications',
        ),
      ],
      debug: kDebugMode,
    );

    plugin.setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload?['taskId'];
    if (payload != null && onNotificationTapped != null) {
      onNotificationTapped!(payload);
    }
  }

  static Future<void> requestPermissions() async {
    await plugin.requestPermissionToSendNotifications(
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        NotificationPermission.PreciseAlarms,
      ],
    );
  }

  static Future<bool> canScheduleExact() async {
    final allowed = await plugin.isNotificationAllowed();
    if (!allowed) return false;
    final permissions = await plugin.checkPermissionList(
      permissions: [NotificationPermission.PreciseAlarms],
    );
    return permissions.contains(NotificationPermission.PreciseAlarms);
  }

  static Future<bool> ensureExactAlarmPermission(BuildContext context) async {
    final hasExact = await canScheduleExact();
    if (hasExact) return true;

    final allowed = await plugin.requestPermissionToSendNotifications(
      permissions: [NotificationPermission.PreciseAlarms],
    );
    if (allowed) {
      final permissions = await plugin.checkPermissionList(
        permissions: [NotificationPermission.PreciseAlarms],
      );
      if (permissions.contains(NotificationPermission.PreciseAlarms)) {
        return true;
      }
    }

    await plugin.showAlarmPage();
    return false;
  }

  static Future<void> cancelAll() => plugin.cancelAll();
  static Future<void> cancel(int id) => plugin.cancel(id);
}
