import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/profile/presentation/providers/profile_provider.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';

void main() {
  group('MemberProfileStats', () {
    test('summarizes member tasks', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final tasks = [
        Task(
          id: '1',
          title: 'Design',
          tags: const ['work'],
          startMinutes: now.hour * 60,
          durationMinutes: 120,
          status: TaskStatus.done,
          createdAt: now,
          updatedAt: now,
          taskDate: today,
        ),
        Task(
          id: '2',
          title: 'Inbox',
          tags: const ['work'],
          createdAt: now,
          updatedAt: now,
          taskDate: today,
        ),
        Task(
          id: '3',
          title: 'Gym',
          tags: const ['health'],
          startMinutes: 14 * 60,
          createdAt: now,
          updatedAt: now,
          taskDate: yesterday,
        ),
      ];

      final stats = MemberProfileStats.fromTasks(tasks);

      expect(stats.totalTasks, 3);
      expect(stats.completedTasks, 1);
      expect(stats.scheduledTasks, 2);
      expect(stats.inProgressTasks, 1);
      expect(stats.topTag, 'work');
      expect(stats.mostActiveHour, now.hour);
      expect(stats.createdThisWeek, 3);
      expect(stats.completionRate, closeTo(1 / 3, 0.0001));
    });
  });
}
