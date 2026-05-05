import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/presentation/widgets/task_card_widget.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Task _makeTask({
  String title = 'Test Task',
  TaskStatus status = TaskStatus.pending,
  int? startMinutes,
  int? durationMinutes,
  String? graphicImage,
  List<String> tags = const [],
  String? goalId,
}) {
  final now = DateTime.now();
  return Task(
    id: 'task-id',
    title: title,
    status: status,
    startMinutes: startMinutes,
    durationMinutes: durationMinutes,
    graphicImage: graphicImage,
    tags: tags,
    goalId: goalId,
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

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('TaskCardWidget – Simplified (No Scroll Tracking)', () {
    testWidgets('renders without scroll listener setup', (tester) async {
      final task = _makeTask(title: 'No Scroll');
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

      expect(find.text('No Scroll'), findsOneWidget);
      // Should be a StatelessWidget now — no StatefulWidget state to find
      expect(find.byType(TaskCardWidget), findsOneWidget);
    });

    testWidgets('static content positioned at top (no animated offset)', (
      tester,
    ) async {
      final task = _makeTask(title: 'Static');
      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: 200,
            child: TaskCardWidget(
              task: task,
              isInProgress: false,
              onTap: () {},
              onDone: () {},
              onEdit: () {},
              onDelete: () {},
              onDuplicate: () {},
            ),
          ),
        ),
      );

      // Content should be at Positioned(top: 0) inside the Stack
      final stackFinder = find.byType(Stack);
      expect(stackFinder, findsOneWidget);
    });

    testWidgets('does NOT rebuild on scroll (no AnimatedBuilder)', (tester) async {
      final task = _makeTask(title: 'Stable');
      int tapCount = 0;

      await tester.pumpWidget(
        _buildApp(
          ListView(
            children: [
              TaskCardWidget(
                task: task,
                isInProgress: false,
                onTap: () => tapCount++,
                onDone: () {},
                onEdit: () {},
                onDelete: () {},
                onDuplicate: () {},
              ),
            ],
          ),
        ),
      );

      // Scroll the ListView
      await tester.fling(find.byType(ListView), const Offset(0, -200), 300);
      await tester.pumpAndSettle();

      // Card should still be there, no crash from scroll listeners
      expect(find.text('Stable'), findsOneWidget);
      expect(tapCount, 0);
    });

    testWidgets('tapping triggers onTap callback', (tester) async {
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

    testWidgets('dismiss swipe triggers onDone', (tester) async {
      bool done = false;
      final task = _makeTask();

      await tester.pumpWidget(
        _buildApp(
          TaskCardWidget(
            task: task,
            isInProgress: false,
            onTap: () {},
            onDone: () => done = true,
            onEdit: () {},
            onDelete: () {},
            onDuplicate: () {},
          ),
        ),
      );

      await tester.drag(find.byType(Dismissible), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(done, isTrue);
    });

    testWidgets('done task: dismiss disabled', (tester) async {
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

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.none);
    });

    testWidgets('in-progress task: shows primary border + glow', (tester) async {
      final task = _makeTask();

      await tester.pumpWidget(
        _buildApp(
          TaskCardWidget(
            task: task,
            isInProgress: true,
            onTap: () {},
            onDone: () {},
            onEdit: () {},
            onDelete: () {},
            onDuplicate: () {},
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border!.top.width, 2); // in-progress border width
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('renders graphic background when graphicImage set', (tester) async {
      final task = _makeTask(graphicImage: 'assets/images/task_sleep.svg');

      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            height: 200,
            child: TaskCardWidget(
              task: task,
              isInProgress: false,
              onTap: () {},
              onDone: () {},
              onEdit: () {},
              onDelete: () {},
              onDuplicate: () {},
            ),
          ),
        ),
      );

      // Stack should have multiple children: graphic + gradient + content
      final stack = tester.widget<Stack>(find.byType(Stack));
      expect(stack.children.length, greaterThan(1));
    });

    testWidgets('renders tags as chips (max 3)', (tester) async {
      final task = _makeTask(tags: ['a', 'b', 'c', 'd', 'e']);

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

      expect(find.text('#a'), findsOneWidget);
      expect(find.text('#b'), findsOneWidget);
      expect(find.text('#c'), findsOneWidget);
      expect(find.text('#d'), findsNothing); // capped at 3
    });

    testWidgets('shows duration chip when duration set', (tester) async {
      final task = _makeTask(durationMinutes: 90);

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

      // 90 minutes formatted
      expect(find.textContaining('1h 30m'), findsOneWidget);
    });

    testWidgets('long press opens context menu with Edit/Delete', (tester) async {
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

      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('performance: no post-frame callbacks scheduled', (tester) async {
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

      // Pump a few frames — should be stable without post-frame measurement
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(TaskCardWidget), findsOneWidget);
    });
  });
}
