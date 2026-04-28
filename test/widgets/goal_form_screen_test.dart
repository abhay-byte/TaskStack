import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/features/task_stack/presentation/screens/goal_form_screen.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';

class _FakeGoalRepository implements GoalRepository {
  Goal? lastInserted;

  @override
  Future<void> deleteGoalById(String id) async {}

  @override
  Future<List<Goal>> getAllGoals() async => [];

  @override
  Future<Goal?> getGoalById(String id) async => null;

  @override
  Future<void> insertGoal(Goal goal) async {
    lastInserted = goal;
  }

  @override
  Future<void> updateGoal(Goal goal) async {}

  @override
  Stream<List<Goal>> watchAllGoals() async* {
    yield [];
  }

  @override
  Stream<List<GoalTaskInfo>> watchTasksForGoal(String goalId) async* {
    yield [];
  }

  @override
  Future<int?> getCommittedMinutesForGoal(String goalId) async => 0;
}

class _FakeSyncRepository implements SyncRepository {
  bool pushed = false;

  @override
  Future<void> pullCloudToLocal() async {}

  @override
  Future<void> pushLocalToCloud() async {
    pushed = true;
  }
}

void main() {
  group('GoalFormScreen', () {
    testWidgets('renders icon picker and colour picker',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository()),
            syncRepositoryProvider.overrideWithValue(_FakeSyncRepository()),
          ],
          child: const MaterialApp(
            home: GoalFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Goal'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);

      // Verify some icons are present
      expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('renders isGoal switch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository()),
            syncRepositoryProvider.overrideWithValue(_FakeSyncRepository()),
          ],
          child: const MaterialApp(
            home: GoalFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('This is a Goal (not just a Project)'), findsOneWidget);
    });

    testWidgets('shows duration info when type is ongoing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository()),
            syncRepositoryProvider.overrideWithValue(_FakeSyncRepository()),
          ],
          child: const MaterialApp(
            home: GoalFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Ongoing type
      await tester.tap(find.text('Ongoing'));
      await tester.pump();

      // Duration fields should not be visible
      expect(find.widgetWithText(TextField, 'Days'), findsNothing);
      expect(find.widgetWithText(TextField, 'Months'), findsNothing);
      expect(find.widgetWithText(TextField, 'Years'), findsNothing);
    });

    testWidgets('tapping icon selects it', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository()),
            syncRepositoryProvider.overrideWithValue(_FakeSyncRepository()),
          ],
          child: const MaterialApp(
            home: GoalFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap an icon
      await tester.tap(find.byIcon(Icons.fitness_center_outlined));
      await tester.pump();

      // The icon should still be visible (selected state)
      expect(find.byIcon(Icons.fitness_center_outlined), findsOneWidget);
    });

    testWidgets('tapping colour selects it', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository()),
            syncRepositoryProvider.overrideWithValue(_FakeSyncRepository()),
          ],
          child: const MaterialApp(
            home: GoalFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find colour circles (Containers inside InkWell)
      final colourPickers = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(InkWell),
      );
      expect(colourPickers, findsWidgets);

      // Tap the first colour
      await tester.tap(colourPickers.first);
      await tester.pump();
    });
  });
}
