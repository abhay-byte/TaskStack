import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/task_card_widget.dart';

void main() {
  Task _makeTask({TaskStatus status = TaskStatus.pending}) {
    final now = DateTime.now();
    return Task(
      id: 'wt-id',
      title: 'Widget Test Task',
      description: 'A task for widget testing',
      tags: ['work', 'flutter'],
      startMinutes: now.hour * 60,
      durationMinutes: 60,
      status: status,
      createdAt: now,
      updatedAt: now,
      taskDate: now,
    );
  }

  Widget _buildApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  group('TaskCardWidget', () {
    testWidgets('shows task title', (tester) async {
      final task = _makeTask();
      await tester.pumpWidget(
        _buildApp(
          TaskCardWidget(
            task: task,
            isInProgress: false,
            onTap: () {},
            onDone: () {},
            onEdit: () {},
            onDelete: () {},
            onDuplicate: () {},
          ),
        ),
      );
      expect(find.text('Widget Test Task'), findsOneWidget);
    });

    testWidgets('shows tags as #tag chips', (tester) async {
      final task = _makeTask();
      await tester.pumpWidget(
        _buildApp(
          TaskCardWidget(
            task: task,
            isInProgress: false,
            onTap: () {},
            onDone: () {},
            onEdit: () {},
            onDelete: () {},
            onDuplicate: () {},
          ),
        ),
      );
      expect(find.text('#work'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      final task = _makeTask();
      await tester.pumpWidget(
        _buildApp(
          TaskCardWidget(
            task: task,
            isInProgress: false,
            onTap: () => tapped = true,
            onDone: () {},
            onEdit: () {},
            onDelete: () {},
            onDuplicate: () {},
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows check_circle icon for done task', (tester) async {
      final task = _makeTask(status: TaskStatus.done);
      await tester.pumpWidget(
        _buildApp(
          TaskCardWidget(
            task: task,
            isInProgress: false,
            onTap: () {},
            onDone: () {},
            onEdit: () {},
            onDelete: () {},
            onDuplicate: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
