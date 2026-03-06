import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/notifications/notification_service.dart';

class NotificationScheduler {
  static bool _tzInitialised = false;

  static Future<void> initTimezone() async {
    if (!_tzInitialised) {
      tz_data.initializeTimeZones();
      _tzInitialised = true;
    }
  }

  Future<void> scheduleFor(Task task) async {
    if (!task.notificationEnabled || task.startMinutes == null) return;
    await initTimezone();

    final now = tz.TZDateTime.now(tz.local);
    final notifyStart = task.startMinutes! - task.notificationOffsetMinutes;
    final scheduled = tz.TZDateTime(
      tz.local,
      task.taskDate.year,
      task.taskDate.month,
      task.taskDate.day,
      0, // Start at midnight
      notifyStart, // Add exact minutes (TZDateTime handles negative minutes correctly)
    );

    if (scheduled.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'taskstack_tasks',
      'Task Reminders',
      channelDescription: 'Reminders for your scheduled tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await NotificationService.plugin.zonedSchedule(
      id: task.id.hashCode.abs() & 0x7FFFFFFF,
      title: task.title,
      body: task.purpose ?? task.description ?? 'Tap to view your task',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelFor(String taskId) async {
    await NotificationService.plugin.cancel(
      id: taskId.hashCode.abs() & 0x7FFFFFFF,
    );
  }

  Future<void> rescheduleAll(List<Task> tasks) async {
    await NotificationService.plugin.cancelAll();
    for (final task in tasks) {
      await scheduleFor(task);
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler();
});
