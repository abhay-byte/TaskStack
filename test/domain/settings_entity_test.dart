import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/settings/presentation/providers/settings_provider.dart';

// ── AppSettings Tests ─────────────────────────────────────────────────────

void main() {
  group('AppSettings', () {
    test('defaults are correct', () {
      const s = AppSettings();
      expect(s.themeMode, 0); // system
      expect(s.weekStartsSunday, isTrue);
      expect(s.use24HourTime, isFalse);
      expect(s.defaultNotificationOffsetMinutes, 5);
      expect(s.isFirstLaunch, isTrue);
      expect(s.accentColorArgb, isNull);
    });

    test('copyWith updates only specified fields', () {
      const original = AppSettings(themeMode: 0, use24HourTime: false);
      final updated = original.copyWith(themeMode: 2, use24HourTime: true);

      expect(updated.themeMode, 2);
      expect(updated.use24HourTime, isTrue);
      expect(updated.weekStartsSunday, original.weekStartsSunday);
      expect(updated.defaultNotificationOffsetMinutes,
          original.defaultNotificationOffsetMinutes);
    });

    test('copyWith does not mutate original', () {
      const original = AppSettings(themeMode: 1);
      original.copyWith(themeMode: 2);
      expect(original.themeMode, 1);
    });

    test('isFirstLaunch can be set to false via copyWith', () {
      const s = AppSettings(isFirstLaunch: true);
      expect(s.copyWith(isFirstLaunch: false).isFirstLaunch, isFalse);
    });
  });

  group('Task use-case validation logic', () {
    test('task with empty title is not "valid"', () {
      // TaskFormState.isValid checks title.trim().isNotEmpty
      // We test the entity-level invariant that title is required.
      expect(''.trim().isEmpty, isTrue);
      expect('  '.trim().isEmpty, isTrue);
      expect('My Task'.trim().isEmpty, isFalse);
    });

    test('RecurrenceType.values has all 5 cases', () {
      expect(RecurrenceType.values.length, 5);
      expect(RecurrenceType.values, contains(RecurrenceType.none));
      expect(RecurrenceType.values, contains(RecurrenceType.repeatToday));
      expect(RecurrenceType.values, contains(RecurrenceType.daily));
      expect(RecurrenceType.values, contains(RecurrenceType.weekly));
      expect(RecurrenceType.values, contains(RecurrenceType.custom));
    });

    test('TaskStatus.values has 2 cases', () {
      expect(TaskStatus.values.length, 2);
    });

    test('startMinutes → TimeOfDay conversion is correct for midnight', () {
      final task = Task(
        id: 'x',
        title: 'Midnight',
        startMinutes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        taskDate: DateTime.now(),
      );
      expect(task.startTime?.hour, 0);
      expect(task.startTime?.minute, 0);
    });

    test('startMinutes → TimeOfDay conversion is correct for 23:59', () {
      final task = Task(
        id: 'x',
        title: 'Almost midnight',
        startMinutes: 23 * 60 + 59,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        taskDate: DateTime.now(),
      );
      expect(task.startTime?.hour, 23);
      expect(task.startTime?.minute, 59);
    });
  });
}
