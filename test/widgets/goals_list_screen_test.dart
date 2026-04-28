import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/task_stack/domain/entities/goal.dart';
import 'package:taskstack/features/task_stack/domain/repositories/goal_repository.dart';
import 'package:taskstack/features/task_stack/data/repositories/goal_repository_impl.dart';
import 'package:taskstack/features/task_stack/presentation/providers/goal_providers.dart';
import 'package:taskstack/features/task_stack/presentation/screens/goals_list_screen.dart';

class _FakeGoalRepository implements GoalRepository {
  _FakeGoalRepository(this._goals);

  final List<Goal> _goals;

  @override
  Future<void> deleteGoalById(String id) async {}

  @override
  Future<List<Goal>> getAllGoals() async => _goals;

  @override
  Future<Goal?> getGoalById(String id) async {
    for (final goal in _goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  @override
  Future<void> insertGoal(Goal goal) async {}

  @override
  Future<void> updateGoal(Goal goal) async {}

  @override
  Stream<List<Goal>> watchAllGoals() async* {
    yield _goals;
  }

  @override
  Stream<List<GoalTaskInfo>> watchTasksForGoal(String goalId) async* {
    yield [];
  }

  @override
  Future<int?> getCommittedMinutesForGoal(String goalId) async => 120;
}

void main() {
  group('GoalsListScreen', () {
    testWidgets('renders "Goals" app bar title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository([])),
          ],
          child: MaterialApp(
            home: const GoalsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Goals & Projects'), findsNothing);
    });

    testWidgets('shows empty state when no goals', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(_FakeGoalRepository([])),
          ],
          child: const MaterialApp(
            home: GoalsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No goals yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders goal card with progress bar', (tester) async {
      final now = DateTime.now();
      final goal = Goal(
        id: 'g1',
        title: 'Learn Flutter',
        type: GoalType.project,
        durationHours: 10,
        iconId: 'school',
        colorArgb: 0xFF3B82F6,
        isGoal: true,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(
              _FakeGoalRepository([goal]),
            ),
          ],
          child: const MaterialApp(
            home: GoalsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learn Flutter'), findsOneWidget);
      expect(find.text('Project Goal'), findsOneWidget);
      expect(find.text('10 hrs'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders goal card with custom icon and colour',
        (tester) async {
      final now = DateTime.now();
      final goal = Goal(
        id: 'g2',
        title: 'Fitness',
        type: GoalType.habit,
        durationHours: 50,
        iconId: 'fitness_center',
        colorArgb: 0xFF22C55E,
        isGoal: false,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(
              _FakeGoalRepository([goal]),
            ),
          ],
          child: const MaterialApp(
            home: GoalsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fitness'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final now = DateTime.now();
      final goal = Goal(
        id: 'g3',
        title: 'Deletable',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalRepositoryProvider.overrideWithValue(
              _FakeGoalRepository([goal]),
            ),
          ],
          child: const MaterialApp(
            home: GoalsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Goal'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
