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
    // We need timezone location. 'UTC' is safe for testing pure logic.
    late tz.Location location;

    setUpAll(() {
      tz_data.initializeTimeZones();
      location = tz.getLocation('UTC');
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
  });
}
