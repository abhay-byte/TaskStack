import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/notifications/notification_service.dart';

enum NotificationScheduleResult {
  scheduled,
  scheduledImmediate,
  skippedDisabled,
  skippedNoStart,
  skippedPastTask,
  failedNoPermission,
  failedPluginError,
}

enum ScheduleType { future, immediate, skippedPast }

class ScheduleCalculation {
  final ScheduleType type;
  final tz.TZDateTime? time;
  
  const ScheduleCalculation(this.type, [this.time]);
}

ScheduleCalculation calculateScheduleTime(
  tz.TZDateTime now,
  DateTime taskDate,
  int startMinutes,
  int offsetMinutes,
  tz.Location location,
) {
  final notifyStart = startMinutes - offsetMinutes;
  var scheduled = tz.TZDateTime(
    location,
    taskDate.year,
    taskDate.month,
    taskDate.day,
    0,
    notifyStart,
  );

  if (scheduled.isBefore(now)) {
    final taskStart = tz.TZDateTime(
      location,
      taskDate.year,
      taskDate.month,
      taskDate.day,
      0,
      startMinutes,
    );
    if (taskStart.isAfter(now)) {
      return ScheduleCalculation(
        ScheduleType.immediate, 
        now.add(const Duration(seconds: 2)),
      );
    } else {
      return const ScheduleCalculation(ScheduleType.skippedPast);
    }
  }

  return ScheduleCalculation(ScheduleType.future, scheduled);
}

class NotificationScheduler {
  static bool _tzInitialised = false;

  static Future<void> initTimezone() async {
    if (!_tzInitialised) {
      tz_data.initializeTimeZones();
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
      _tzInitialised = true;
    }
  }

  Future<NotificationScheduleResult> scheduleFor(Task task) async {
    debugPrint('NOTIF_SCHEDULE: scheduleFor called task=${task.id} title=${task.title} enabled=${task.notificationEnabled} start=${task.startMinutes} offset=${task.notificationOffsetMinutes} date=${task.taskDate}');
    if (!task.notificationEnabled) {
      debugPrint('NOTIF_SCHEDULE: early return (disabled)');
      return NotificationScheduleResult.skippedDisabled;
    }
    if (task.startMinutes == null) {
      debugPrint('NOTIF_SCHEDULE: early return (no start time)');
      return NotificationScheduleResult.skippedNoStart;
    }

    final hasExactPermission = await NotificationService.canScheduleExact();
    if (!hasExactPermission) {
      debugPrint('NOTIF_SCHEDULE: SKIPPED — exact alarm permission not granted');
      return NotificationScheduleResult.failedNoPermission;
    }

    await initTimezone();

    final now = tz.TZDateTime.now(tz.local);
    final calc = calculateScheduleTime(
      now, 
      task.taskDate, 
      task.startMinutes!, 
      task.notificationOffsetMinutes, 
      tz.local,
    );

    if (calc.type == ScheduleType.skippedPast) {
      debugPrint('NOTIF_SCHEDULE: SKIPPED — task start time is in the past');
      return NotificationScheduleResult.skippedPastTask;
    }

    final scheduled = calc.time!;
    final isImmediate = calc.type == ScheduleType.immediate;

    if (isImmediate) {
      debugPrint('NOTIF_SCHEDULE: rescheduled to immediate ($scheduled) because remind time passed but task is in future');
    }

    final localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

    try {
      final ok = await NotificationService.plugin.createNotification(
        content: NotificationContent(
          id: task.id.hashCode.abs() & 0x7FFFFFFF,
          channelKey: 'taskstack_tasks',
          title: task.title,
          body: task.purpose ?? task.description ?? 'Tap to view your task',
          payload: {'taskId': task.id},
          wakeUpScreen: true,
          category: NotificationCategory.Alarm,
        ),
        schedule: NotificationCalendar(
          year: scheduled.year,
          month: scheduled.month,
          day: scheduled.day,
          hour: scheduled.hour,
          minute: scheduled.minute,
          second: scheduled.second,
          millisecond: scheduled.millisecond,
          timeZone: localTimeZone,
          preciseAlarm: true,
          allowWhileIdle: true,
          repeats: false,
        ),
      );
      if (!ok) {
        debugPrint('NOTIF_SCHEDULE: WARNING for ${task.id} (plugin returned false, but may have succeeded)');
        // We do not return failedPluginError here because awesome_notifications 
        // can return false even when the alarm is successfully scheduled (e.g., edge cases).
      }
      debugPrint('NOTIF_SCHEDULE: SUCCESS for ${task.id}');
      return isImmediate
          ? NotificationScheduleResult.scheduledImmediate
          : NotificationScheduleResult.scheduled;
    } catch (e) {
      debugPrint('NOTIF_SCHEDULE: FAILED for ${task.id}: $e');
      return NotificationScheduleResult.failedPluginError;
    }
  }

  Future<void> cancelFor(String taskId) async {
    await NotificationService.plugin.cancel(
      taskId.hashCode.abs() & 0x7FFFFFFF,
    );
  }

  Future<void> rescheduleAll(List<Task> tasks) async {
    for (final task in tasks) {
      await cancelFor(task.id);
      await scheduleFor(task);
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler();
});
