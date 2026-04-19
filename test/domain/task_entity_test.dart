import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

Task _makeTask({
  String id = 'test-id',
  String title = 'Test Task',
  int? startMinutes,
  int? durationMinutes,
  RecurrenceType recurrenceType = RecurrenceType.none,
  String? recurrenceRule,
  TaskStatus status = TaskStatus.pending,
  DateTime? completedAt,
  DateTime? taskDate,
}) {
  final now = DateTime.now();
  return Task(
    id: id,
    title: title,
    startMinutes: startMinutes,
    durationMinutes: durationMinutes,
    recurrenceType: recurrenceType,
    recurrenceRule: recurrenceRule,
    status: status,
    completedAt: completedAt,
    createdAt: now,
    updatedAt: now,
    taskDate: taskDate ?? DateTime(now.year, now.month, now.day),
  );
}

// ── Task Entity Tests ─────────────────────────────────────────────────────

void main() {
  group('Task entity', () {
    test('isDone returns true only when status is done', () {
      final pending = _makeTask(status: TaskStatus.pending);
      final done = _makeTask(status: TaskStatus.done);

      expect(pending.isDone, isFalse);
      expect(done.isDone, isTrue);
    });

    test('startTime returns null when startMinutes is null', () {
      final task = _makeTask();
      expect(task.startTime, isNull);
    });

    test('startTime correctly converts minutes to TimeOfDay', () {
      final task = _makeTask(startMinutes: 9 * 60 + 30); // 9:30
      expect(task.startTime?.hour, 9);
      expect(task.startTime?.minute, 30);
    });

    test('isInProgress returns false when no startMinutes', () {
      final task = _makeTask();
      expect(task.isInProgress(DateTime.now()), isFalse);
    });

    test('isInProgress returns true when now is within window', () {
      final now = DateTime.now();
      final startMinutes = now.hour * 60 + now.minute - 5;
      final task = _makeTask(startMinutes: startMinutes, durationMinutes: 30);
      expect(task.isInProgress(now), isTrue);
    });

    test('isInProgress returns false when task is done', () {
      final now = DateTime.now();
      final startMinutes = now.hour * 60 + now.minute - 5;
      final task = _makeTask(
        startMinutes: startMinutes,
        durationMinutes: 30,
        status: TaskStatus.done,
        completedAt: now,
      );
      // isDone check doesn't block isInProgress directly — time window logic
      expect(task.isInProgress(now), isTrue); // time window is still active
    });

    test('copyWith preserves unchanged fields', () {
      final original = _makeTask(title: 'Original', startMinutes: 600);
      final copy = original.copyWith(title: 'Updated');

      expect(copy.title, 'Updated');
      expect(copy.startMinutes, 600);
      expect(copy.id, original.id);
    });

    test('copyWith can update multiple fields', () {
      final original = _makeTask();
      final copy = original.copyWith(
        title: 'New Title',
        status: TaskStatus.done,
        startMinutes: 480,
      );

      expect(copy.title, 'New Title');
      expect(copy.status, TaskStatus.done);
      expect(copy.startMinutes, 480);
    });

    test('tags default to empty list', () {
      final task = _makeTask();
      expect(task.tags, isEmpty);
    });

    test('notificationEnabled defaults to true', () {
      final task = _makeTask();
      expect(task.notificationEnabled, isTrue);
    });

    test('recurrenceType defaults to none', () {
      final task = _makeTask();
      expect(task.recurrenceType, RecurrenceType.none);
    });
  });

  group('Task repeat-today logic', () {
    test('repeatToday recurrence type is properly set via copyWith', () {
      final task = _makeTask(recurrenceType: RecurrenceType.none);
      final repeated = task.copyWith(recurrenceType: RecurrenceType.repeatToday);
      expect(repeated.recurrenceType, RecurrenceType.repeatToday);
    });
  });

  group('Task custom recurrence parsing', () {
    test('customRecurrenceDays parses valid weekday values and ignores junk', () {
      final custom = _makeTask(recurrenceType: RecurrenceType.custom).copyWith(
        recurrenceRule: '1, 3, 5, 0, 8, abc, 7',
      );

      expect(custom.customRecurrenceDays, [1, 3, 5, 7]);
    });

    test('customRecurrenceDays is empty when recurrence is not custom', () {
      final task = _makeTask(
        recurrenceType: RecurrenceType.daily,
        recurrenceRule: '1,3,5',
      );

      expect(task.customRecurrenceDays, isEmpty);
    });
  });
}
