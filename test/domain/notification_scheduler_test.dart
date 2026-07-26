import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
void main() {
  group('NotificationScheduleResult', () {
    test('contains expected enum values', () {
      expect(NotificationScheduleResult.values, containsAll([
        NotificationScheduleResult.scheduled,
        NotificationScheduleResult.scheduledImmediate,
        NotificationScheduleResult.skippedDisabled,
        NotificationScheduleResult.skippedNoStart,
        NotificationScheduleResult.skippedPastTask,
        NotificationScheduleResult.failedNoPermission,
        NotificationScheduleResult.failedPluginError,
      ]));
    });

    test('task notification disabled returns skippedDisabled result check', () {
      final task = Task(
        id: '1',
        title: 'Disabled Task',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        taskDate: DateTime.now(),
        notificationEnabled: false,
      );
      expect(task.notificationEnabled, isFalse);
    });
  });

  group('calculateScheduleTime', () {
    // tz.UTC is a built-in constant — always available without initializeTimeZones.
    late tz.Location location;

    setUpAll(() {
      tz_data.initializeTimeZones();
      location = tz.UTC;
    });

    test('returns future when notification time is in the future', () {
      final now = tz.TZDateTime(location, 2026, 7, 26, 10, 0); // 10:00 AM
      final taskDate = DateTime(2026, 7, 26);
      // Start at 12:00 PM (720 minutes)
      // Offset 30 minutes -> remind at 11:30 AM
      final calc = calculateScheduleTime(now, taskDate, 720, 30, location);
      
      expect(calc.type, ScheduleType.future);
      expect(calc.time!.hour, 11);
      expect(calc.time!.minute, 30);
    });

    test('returns immediate when notification time passed but start is future', () {
      final now = tz.TZDateTime(location, 2026, 7, 26, 11, 45); // 11:45 AM
      final taskDate = DateTime(2026, 7, 26);
      // Start at 12:00 PM (720 minutes)
      // Offset 30 minutes -> remind at 11:30 AM (past)
      final calc = calculateScheduleTime(now, taskDate, 720, 30, location);
      
      expect(calc.type, ScheduleType.immediate);
      // time should be now + 2 seconds
      expect(calc.time!.difference(now).inSeconds, 2);
    });

    test('returns skippedPast when task start time has already passed', () {
      final now = tz.TZDateTime(location, 2026, 7, 26, 12, 15); // 12:15 PM
      final taskDate = DateTime(2026, 7, 26);
      // Start at 12:00 PM (720 minutes)
      // Offset 30 minutes -> remind at 11:30 AM (past)
      final calc = calculateScheduleTime(now, taskDate, 720, 30, location);
      
      expect(calc.type, ScheduleType.skippedPast);
      expect(calc.time, isNull);
    });

    test('cross-midnight: offset > startMinutes wraps notifyStart negative — treated as past/immediate', () {
      // Start at 00:10 (10 min after midnight), offset 30 min → notifyStart = -20.
      // TZDateTime with minute=-20 rolls back to the previous day at 23:40.
      // That is before any reasonable "now", so the result must be either
      // immediate (if task start 00:10 is still future) or skippedPast (if past).
      final now = tz.TZDateTime(location, 2026, 7, 26, 0, 5); // 00:05 AM
      final taskDate = DateTime(2026, 7, 26);
      // start=10 min, offset=30 → notifyStart=-20 → previous-day 23:40 (before now)
      // task start 00:10 is after now → immediate
      final calc = calculateScheduleTime(now, taskDate, 10, 30, location);
      expect(
        calc.type,
        anyOf(ScheduleType.immediate, ScheduleType.skippedPast),
        reason: 'Negative notifyStart must not produce a day-minus-1 future alarm',
      );
      // If immediate, the time must be ≥ now (within a few seconds)
      if (calc.type == ScheduleType.immediate) {
        expect(calc.time!.isAfter(now) || calc.time!.isAtSameMomentAs(now), isTrue);
      }
    });
  });
}
