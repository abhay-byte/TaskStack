# TaskStack — Software Design Document (SDD)

**Document Version:** 1.0  
**Date:** 2026-02-28  
**Project:** TaskStack — Advanced Daily Task Management & Analytics App  
**Platform:** Flutter (Android & iOS)  
**Status:** Draft

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architectural Overview](#2-architectural-overview)
3. [Folder & Module Structure](#3-folder--module-structure)
4. [Data Layer Design](#4-data-layer-design)
5. [Domain Layer Design](#5-domain-layer-design)
6. [Presentation Layer Design](#6-presentation-layer-design)
7. [Navigation Design](#7-navigation-design)
8. [24-Hour Stack — Detailed Design](#8-24-hour-stack--detailed-design)
9. [Notification System Design](#9-notification-system-design)
10. [Analytics Engine Design](#10-analytics-engine-design)
11. [State Management Strategy](#11-state-management-strategy)
12. [Database Schema](#12-database-schema)
13. [UI Design System](#13-ui-design-system)
14. [Error Handling Strategy](#14-error-handling-strategy)
15. [Testing Strategy](#15-testing-strategy)
16. [Deployment & Build Strategy](#16-deployment--build-strategy)

---

## 1. Introduction

### 1.1 Purpose
This Software Design Document (SDD) provides the complete technical architecture and design specifications for TaskStack v1.0. It translates the requirements defined in the SRS into a concrete Flutter implementation blueprint, covering system architecture, module design, data models, UI component hierarchy, and cross-cutting concerns.

### 1.2 Scope
This document covers the end-to-end design of the TaskStack Flutter application, from SQLite database schema to pixel-level UI component specifications. It is the primary reference for all Flutter developers working on the project.

### 1.3 Design Principles
The following principles guide all architectural decisions in TaskStack:

1. **Offline-First:** All features function without network access; local SQLite is the source of truth.
2. **Clean Architecture:** Strict separation of Presentation → Domain → Data layers; no layer bleeds into another.
3. **Reactive UI:** State changes automatically propagate to the UI via Riverpod providers; no manual `setState` at the feature level.
4. **Testability:** Business logic is fully testable in isolation (no Flutter dependency in domain/data layers).
5. **Performance First:** The 24-hour timeline must scroll at 60 fps; efficient use of `ListView.builder`, `RepaintBoundary`, and minimal widget rebuilds.
6. **Accessibility:** All interactive elements meet WCAG 2.1 AA contrast and touch-target standards.

---

## 2. Architectural Overview

TaskStack follows **Clean Architecture** (as popularised by Robert C. Martin) adapted for Flutter, with three primary layers:

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                    │
│  Screens  │  Widgets  │  Riverpod Notifiers/Providers   │
├─────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                        │
│  Entities  │  Use Cases  │  Repository Interfaces       │
├─────────────────────────────────────────────────────────┤
│                      DATA LAYER                         │
│  Repository Impls  │  Drift DAOs  │  Local Storage      │
└─────────────────────────────────────────────────────────┘
              ↑ Dependency flows upward only
```

### 2.1 Layer Responsibilities

| Layer | Responsibility | Flutter Dependency |
|---|---|---|
| **Presentation** | Render UI, handle user input, display state from providers | Yes (Flutter widgets, Riverpod) |
| **Domain** | Business rules, use case orchestration, entity definitions | No (pure Dart) |
| **Data** | Persist/retrieve data from SQLite, model conversions | Minimal (Drift, dart:convert) |

### 2.2 Key Architectural Flows

#### Task Creation Flow
```
User taps "Save" on Task Form
  → Presentation: TaskFormNotifier.saveTask(taskInput)
    → Domain: CreateTaskUseCase.execute(task)
      → Data: TaskRepository.insertTask(taskModel)
        → Drift DAO inserts into SQLite
      → Domain: NotificationUseCase.scheduleFor(task)
        → flutter_local_notifications schedules alarm
    → Presentation: TaskStackNotifier refreshes timeline
      → TaskStackScreen rebuilds with new task card
```

#### Task Completion Flow
```
User swipes/taps "Done" on Task Card
  → Presentation: TaskCardWidget emits onDone event
    → TaskStackNotifier.markTaskDone(taskId)
      → Domain: CompleteTaskUseCase.execute(taskId, completedAt: now)
        → Data: TaskRepository.updateTaskStatus(taskId, done, completedAt)
        → Domain: AnalyticsSummaryUseCase.refreshDailySummary(today)
      → Presentation: Timeline rebuilds with updated task card (done state)
      → Presentation: Completion animation plays
```

---

## 3. Folder & Module Structure

```
lib/
├── main.dart                        # App entry point, Riverpod ProviderScope
├── app.dart                         # MaterialApp, theme, router config
│
├── core/                            # Cross-cutting infrastructure
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   ├── extensions/
│   │   ├── datetime_extensions.dart
│   │   ├── duration_extensions.dart
│   │   └── string_extensions.dart
│   ├── error/
│   │   ├── failures.dart            # Failure sealed class hierarchy
│   │   └── exceptions.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── notification_utils.dart
│   └── widgets/
│       ├── empty_state_widget.dart
│       ├── loading_widget.dart
│       └── error_widget.dart
│
├── features/
│   ├── task_stack/                  # 24-hour timeline home screen
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── task_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── task_model.dart
│   │   │   └── repositories/
│   │   │       └── task_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── task.dart
│   │   │   ├── repositories/
│   │   │   │   └── task_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_task_usecase.dart
│   │   │       ├── get_tasks_for_date_usecase.dart
│   │   │       ├── update_task_usecase.dart
│   │   │       ├── delete_task_usecase.dart
│   │   │       ├── complete_task_usecase.dart
│   │   │       └── generate_repeat_instances_usecase.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── task_stack_provider.dart
│   │       │   └── task_form_provider.dart
│   │       ├── screens/
│   │       │   ├── task_stack_screen.dart
│   │       │   ├── task_detail_screen.dart
│   │       │   └── task_form_screen.dart
│   │       └── widgets/
│   │           ├── timeline_widget.dart
│   │           ├── task_card_widget.dart
│   │           ├── time_indicator_widget.dart
│   │           ├── hour_marker_widget.dart
│   │           └── unscheduled_section_widget.dart
│   │
│   ├── analytics/                   # Analytics dashboard
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── daily_summary_model.dart
│   │   │   └── repositories/
│   │   │       └── analytics_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── daily_summary.dart
│   │   │   ├── repositories/
│   │   │   │   └── analytics_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_daily_analytics_usecase.dart
│   │   │       ├── get_weekly_analytics_usecase.dart
│   │   │       ├── get_monthly_analytics_usecase.dart
│   │   │       └── get_yearly_analytics_usecase.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── analytics_provider.dart
│   │       ├── screens/
│   │       │   └── analytics_screen.dart
│   │       └── widgets/
│   │           ├── daily_analytics_tab.dart
│   │           ├── weekly_analytics_tab.dart
│   │           ├── monthly_analytics_tab.dart
│   │           ├── yearly_analytics_tab.dart
│   │           ├── productivity_heatmap.dart
│   │           ├── tag_donut_chart.dart
│   │           └── completion_bar_chart.dart
│   │
│   ├── notifications/               # Notification management
│   │   ├── notification_service.dart
│   │   └── notification_scheduler.dart
│   │
│   └── settings/                    # App settings & personalisation
│       ├── data/
│       │   └── settings_datasource.dart  # SharedPreferences wrapper
│       ├── domain/
│       │   └── settings_repository.dart
│       └── presentation/
│           ├── providers/
│           │   └── settings_provider.dart
│           ├── screens/
│           │   └── settings_screen.dart
│           └── widgets/
│               ├── theme_picker_widget.dart
│               └── notification_default_widget.dart
│
└── database/                        # Drift database definition
    ├── app_database.dart            # AppDatabase class
    ├── tables/
    │   ├── tasks_table.dart
    │   ├── tags_table.dart
    │   └── daily_summaries_table.dart
    └── daos/
        ├── task_dao.dart
        ├── tag_dao.dart
        └── analytics_dao.dart
```

---

## 4. Data Layer Design

### 4.1 Drift ORM Database

The app uses **Drift** (formerly `moor`) as the SQLite ORM. Drift provides:
- Type-safe query generation
- Reactive streams via `watchSingle()` and `watch()` for automatic UI updates
- Migration support for schema version upgrades

#### `AppDatabase` class
```dart
@DriftDatabase(
  tables: [TasksTable, TagsTable, DailySummariesTable],
  daos: [TaskDao, TagDao, AnalyticsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;  // v6: rolling window cleanup for recurring tasks

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasksTable, tasksTable.graphicImage);
      }
      if (from < 3) {
        await m.createTable(goalsTable);
        await m.addColumn(tasksTable, tasksTable.goalId);
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE "goals" ADD COLUMN "updated_at" INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement('UPDATE "goals" SET "updated_at" = "created_at"');
      }
      if (from < 5) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS deleted_tasks (
            id TEXT NOT NULL PRIMARY KEY,
            deleted_at INTEGER NOT NULL
          )
        ''');
      }
      if (from < 6) {
        // Rolling window: clean up old generated recurring instances
        await _cleanupOldRecurringInstances();
      }
    },
  );
}

Future<void> _cleanupOldRecurringInstances() async {
  final cutoff = DateTime.now().subtract(const Duration(days: 14));
  final dateStr =
      '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
  await customStatement('''
    DELETE FROM tasks
    WHERE parent_task_id IS NOT NULL
      AND task_date < ?
      AND status = 'pending'
      AND completed_at IS NULL
  ''', [dateStr]);
}
```

### 4.2 Repository Pattern

Each feature has a **Repository Interface** (in domain layer) and a **Repository Implementation** (in data layer). This decoupling enables:
- Easy unit testing (mock repository in tests)
- Potential data source swap (e.g., switch SQLite for Firebase) without touching domain logic

```dart
// Domain layer — abstract interface
abstract class TaskRepository {
  Future<void> insertTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Stream<List<Task>> watchTasksForDate(DateTime date);
  Future<Task?> getTaskById(String id);
}

// Data layer — concrete implementation
class TaskRepositoryImpl implements TaskRepository {
  final TaskDao _taskDao;
  TaskRepositoryImpl(this._taskDao);

  @override
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    return _taskDao
        .watchTasksForDate(date)
        .map((models) => models.map((m) => m.toDomain()).toList());
  }
  // ... other implementations
}
```

---

## 5. Domain Layer Design

### 5.1 Core Entity — Task
```dart
class Task {
  final String id;
  final String title;
  final String? description;
  final String? purpose;
  final String? iconId;
  final int? colorARGB;
  final List<String> tags;
  final TimeOfDay? startTime;
  final int? durationMinutes;
  final RecurrenceType recurrenceType;
  final String? recurrenceRule;
  final int? repeatIntervalMinutes;
  final bool notificationEnabled;
  final int notificationOffsetMinutes;
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentTaskId;
  final DateTime date;

  bool get isOverdue => ...
  bool get isInProgress => ...
  Duration get timeUntilStart => ...
}
```

### 5.2 Use Cases

Each use case is a single-purpose class with an `execute()` method:

```dart
class CreateTaskUseCase {
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;

  Future<Either<Failure, void>> execute(Task task) async {
    try {
      await _repository.insertTask(task);
      if (task.notificationEnabled && task.startTime != null) {
        await _scheduler.scheduleFor(task);
      }
      // Handle intra-day repeat instances if recurrenceType == repeatToday
      if (task.recurrenceType == RecurrenceType.repeatToday) {
        final instances = GenerateRepeatInstancesUseCase(task).execute();
        for (final instance in instances) {
          await _repository.insertTask(instance);
          if (instance.notificationEnabled) {
            await _scheduler.scheduleFor(instance);
          }
        }
      }
      // NOTE: daily/weekly/custom recurring tasks NO LONGER generate 365 rows here.
      // A rolling 2-week window is maintained by MaintainRecurringWindowUseCase.
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

/// Maintains a rolling 2-week window of recurring task instances.
/// Window: 7 days back + 14 days forward = 21 days total.
/// Old pending instances outside the window are trimmed.
class MaintainRecurringWindowUseCase {
  final TaskRepository _repository;
  final NotificationScheduler _scheduler;

  Future<void> execute({String? specificParentId}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 7));
    final windowEnd = today.add(const Duration(days: 14));

    final parents = specificParentId != null
        ? [await _repository.getTaskById(specificParentId)].whereType<Task>()
        : await _repository.getRecurringParents();

    for (final parent in parents) {
      if (parent.recurrenceType == RecurrenceType.none ||
          parent.recurrenceType == RecurrenceType.repeatToday) continue;

      // 1. Compute expected dates in window
      final expected = _expectedDates(parent, windowStart, windowEnd);
      if (expected.isEmpty) continue;

      // 2. Find existing instances
      final existing = await _repository.getInstanceDatesInRange(
        parent.id, windowStart, windowEnd,
      );
      final existingSet = existing.map(DateTime.parse).map(_normalize).toSet();

      // 3. Insert missing
      final missing = expected.where((d) => !existingSet.contains(d));
      final instances = missing.map((d) => parent.copyWith(
        id: _uuid.v4(),
        taskDate: d,
        parentTaskId: parent.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: TaskStatus.pending,
      )).toList();

      if (instances.isNotEmpty) {
        await _repository.insertTasks(instances);
        for (final inst in instances.take(10)) {
          if (inst.notificationEnabled) await _scheduler.scheduleFor(inst);
        }
      }

      // 4. Trim old pending instances
      await _repository.deleteOldPendingInstances(parent.id, windowStart);
    }
  }
}
```

### 5.3 Failure Hierarchy
```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure { ... }
class NotificationFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
```

---

## 6. Presentation Layer Design

### 6.1 Screen Inventory

| Screen | Route | Description |
|---|---|---|
| `TaskStackScreen` | `/` | 24-hour timeline home screen |
| `TaskDetailScreen` | `/task/:id` | Full task details + complete/edit buttons |
| `TaskFormScreen` | `/task/new` & `/task/:id/edit` | Create / Edit task form |
| `AnalyticsScreen` | `/analytics` | Tabbed analytics dashboard |
| `SettingsScreen` | `/settings` | App preferences |
| `OnboardingScreen` | `/onboarding` | First-launch walkthrough (4 pages) |

### 6.2 Riverpod Provider Architecture

```dart
// Task stream for today's stack
final taskStackProvider = StreamProvider.family<List<Task>, DateTime>((ref, date) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksForDate(date);
});

// Current selected date for the stack
final selectedStackDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Derived: tasks sorted by startTime for timeline rendering
final sortedTasksProvider = Provider<List<Task>>((ref) {
  final date = ref.watch(selectedStackDateProvider);
  final asyncTasks = ref.watch(taskStackProvider(date));
  return asyncTasks.when(
    data: (tasks) => tasks..sort((a, b) => ...),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Task form editing state
final taskFormProvider = StateNotifierProvider.autoDispose<TaskFormNotifier, TaskFormState>(
  (ref) => TaskFormNotifier(
    createUseCase: ref.watch(createTaskUseCaseProvider),
    updateUseCase: ref.watch(updateTaskUseCaseProvider),
  ),
);
```

---

## 7. Navigation Design

TaskStack uses **GoRouter** for declarative routing with deep-link support from notifications.

### 7.1 Route Structure
```dart
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final isFirstLaunch = ref.read(settingsProvider).isFirstLaunch;
    if (isFirstLaunch) return '/onboarding';
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => TaskStackScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => AnalyticsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
      ],
    ),
    GoRoute(path: '/task/new', builder: (_, __) => TaskFormScreen()),
    GoRoute(path: '/task/:id', builder: (c, s) => TaskDetailScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/task/:id/edit', builder: (c, s) => TaskFormScreen(id: s.pathParameters['id'])),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
  ],
);
```

### 7.2 Bottom Navigation
The `AppShell` widget wraps shell routes with a `NavigationBar` (Material 3):

| Tab | Icon | Route |
|---|---|---|
| Stack | `schedule_rounded` | `/` |
| Analytics | `bar_chart_rounded` | `/analytics` |
| Settings | `settings_rounded` | `/settings` |

---

## 8. Twenty-Four-Hour Stack — Detailed Design

The timeline is the most complex UI component in TaskStack. Its design is critical to the core user experience.

### 8.1 Timeline Rendering Architecture

```
TaskStackScreen
└── Column
    ├── DateNavigationBar          ← Date switcher + today button
    └── Expanded
        └── TimelineWidget         ← Core scrollable timeline
            ├── ScrollController   ← Programmatic scroll to current time
            ├── Stack (flutter widget)
            │   ├── ListView.builder
            │   │   └── HourSlotWidget × 24  ← One per hour (00–23)
            │   ├── TimeIndicatorWidget      ← Floating current-time line
            │   └── TaskCardsOverlay         ← Absolutely positioned task cards
            └── UnscheduledSection           ← Collapsible bottom section
```

### 8.2 Timeline Coordinate System

```
Timeline height = 24 hours × pixelsPerHour
pixelsPerHour = 120 dp (default, configurable via pinch zoom in v1.5)

Task card top offset = (startTime.hour * 60 + startTime.minute) * minuteHeight
  where minuteHeight = pixelsPerHour / 60 = 2 dp

Task card height = durationMinutes * minuteHeight (minimum: 40 dp)

Current time indicator Y = (currentHour * 60 + currentMinute) * minuteHeight
```

### 8.3 `TimelineWidget` Implementation Sketch

```dart
class TimelineWidget extends ConsumerStatefulWidget { ... }

class _TimelineWidgetState extends ConsumerState<TimelineWidget> {
  late final ScrollController _scrollController;
  late final Timer _timeIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    _timeIndicatorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {}); // Trigger time indicator repaint
    });
  }

  void _scrollToNow() {
    final now = DateTime.now();
    final targetOffset = _minuteToPixel(now.hour * 60 + now.minute)
        - MediaQuery.of(context).size.height * 0.35; // Centre in viewport
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(sortedTasksProvider);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPersistentHeader(delegate: _TimelineHeaderDelegate()),
        SliverStack(
          children: [
            SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => HourSlotWidget(hour: i),
              childCount: 24,
            )),
            // Overlay: task cards positioned absolutely
            ...tasks.where((t) => t.startTime != null).map((task) =>
              _buildPositionedTaskCard(task)
            ),
            // Current time indicator
            _buildTimeIndicator(),
          ],
        ),
      ],
    );
  }
}
```

### 8.4 Task Card Widget States

```
TaskCardWidget
├── pending   → Outlined card, task icon, title, scheduled time label
├── in_progress → Highlighted card with accent colour, pulsing animation border
└── done      → Greyed card, ✓ icon, title with strikethrough, "Completed at HH:mm"
```

Each card supports:
- **Tap:** Open TaskDetailScreen
- **Long-press:** Contextual menu (Edit, Delete, Duplicate)
- **Swipe-right:** Mark as done (with haptic + animation)

---

## 9. Notification System Design

### 9.1 Notification Service Architecture

```dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialise() async {
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Requested at onboarding
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Deep link: navigate to task/:id using GoRouter
    final taskId = response.payload;
    if (taskId != null) {
      AppRouter.router.push('/task/$taskId');
    }
  }
}
```

### 9.2 Notification Scheduler

```dart
class NotificationScheduler {
  Future<void> scheduleFor(Task task) async {
    if (!task.notificationEnabled || task.startTime == null) return;

    final scheduledTime = _computeNotificationTime(task);
    if (scheduledTime.isBefore(DateTime.now())) return;

    await NotificationService.schedule(
      id: task.id.hashCode,
      title: task.title,
      body: task.purpose ?? task.description ?? 'Tap to view',
      scheduledTime: scheduledTime,
      payload: task.id,
    );
  }

  DateTime _computeNotificationTime(Task task) {
    final today = DateTime.now();
    return DateTime(
      today.year, today.month, today.day,
      task.startTime!.hour,
      task.startTime!.minute,
    ).subtract(Duration(minutes: task.notificationOffsetMinutes));
  }

  Future<void> cancelFor(String taskId) async {
    await NotificationService.cancel(taskId.hashCode);
  }

  Future<void> rescheduleAll(List<Task> tasks) async {
    await NotificationService.cancelAll();
    for (final task in tasks.where((t) => t.notificationEnabled)) {
      await scheduleFor(task);
    }
  }
}
```

### 9.3 Boot Receiver (Android)
On Android, scheduled alarms are cancelled when the device restarts. A `BootReceiver` (registered in `AndroidManifest.xml`) will trigger on `BOOT_COMPLETED` and call `rescheduleAll()` via a background Dart isolate using the Flutter background execution API.

---

## 10. Analytics Engine Design

### 10.1 Data Pipeline

```
Raw Task Data (SQLite)
  → AnalyticsDao.query(dateRange)
    → AnalyticsRepository.compute(tasks)
      → DailySummary entities
        → AnalyticsProvider (Riverpod)
          → Chart Widgets (fl_chart)
```

### 10.2 Productivity Score Formula

```
ProductivityScore = (
  0.6 × (completedCount / scheduledCount)    // Completion rate (60% weight)
  + 0.4 × (completedDuration / plannedDuration)  // Duration accuracy (40% weight)
) × 100

Clamped to [0, 100]. If no tasks scheduled: score = null (no data).
```

### 10.3 Analytics Queries

```dart
// Weekly analytics — efficient aggregate query via Drift
Future<List<DailySummary>> getWeeklySummaries(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  return (select(dailySummariesTable)
    ..where((s) => s.date.isBetweenValues(weekStart, weekEnd)))
    .get()
    .then((rows) => rows.map((r) => r.toDomain()).toList());
}
```

### 10.4 Chart Component Map

| Time Horizon | Chart Type | Library Component |
|---|---|---|
| Daily — Hourly activity | Vertical bar chart | `BarChart` |
| Daily — Tag breakdown | Doughnut chart | `PieChart` |
| Weekly — Day comparison | Grouped bar chart | `BarChart` |
| Monthly — Trend line | Line chart | `LineChart` |
| Monthly — Heatmap | Custom grid widget | Custom `GridView` + `ColorTween` |
| Yearly — Heatmap | GitHub-style contribution grid | Custom `Canvas` render |

---

## 11. State Management Strategy

### 11.1 Provider Hierarchy

```
ProviderScope (root)
├── appDatabaseProvider           → AppDatabase singleton
├── taskDaoProvider               → TaskDao (from DB)
├── taskRepositoryProvider        → TaskRepositoryImpl
├── notificationSchedulerProvider → NotificationScheduler
│
├── (Feature: Task Stack)
│   ├── selectedStackDateProvider  → StateProvider<DateTime>
│   ├── taskStackProvider(date)    → StreamProvider<List<Task>>
│   ├── sortedTasksProvider        → Provider<List<Task>> (derived)
│   └── taskFormProvider           → StateNotifierProvider<TaskFormNotifier>
│
├── (Feature: Analytics)
│   ├── analyticsHorizonProvider   → StateProvider<AnalyticsHorizon>
│   ├── dailyAnalyticsProvider(date) → FutureProvider<DailyAnalytics>
│   └── weeklyAnalyticsProvider(week) → FutureProvider<WeeklyAnalytics>
│
└── (Feature: Settings)
    └── settingsProvider           → StateNotifierProvider<SettingsNotifier>
```

### 11.2 Key Design Decisions
- **`StreamProvider`** is used for the task timeline so that any database change (insert/update/delete) automatically refreshes the UI without manual refresh calls — this is the "reactive" benefit of Drift's watch queries.
- **`FutureProvider.family`** is used for analytics since data is computed on demand for a specific time range and does not need live streaming.
- **`.autoDispose`** is applied to form providers to prevent state leaking between form sessions.

---

## 12. Database Schema

### 12.1 `tasks` Table

```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  purpose TEXT,
  icon_id TEXT,
  color_argb INTEGER,
  tags TEXT NOT NULL DEFAULT '[]',          -- JSON array of tag strings
  start_minutes INTEGER,                     -- Minutes from midnight
  duration_minutes INTEGER,
  recurrence_type TEXT NOT NULL DEFAULT 'none',  -- none|repeatToday|daily|weekly|custom
  recurrence_rule TEXT,                      -- iCal RRULE for custom
  repeat_interval_minutes INTEGER,           -- For repeatToday
  notification_enabled INTEGER NOT NULL DEFAULT 1,   -- 0|1
  notification_offset_minutes INTEGER NOT NULL DEFAULT 5,
  status TEXT NOT NULL DEFAULT 'pending',    -- pending|done
  completed_at TEXT,                         -- ISO-8601
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  parent_task_id TEXT REFERENCES tasks(id),  -- For recurrence instances
  task_date TEXT NOT NULL                    -- yyyy-MM-dd
);

CREATE INDEX idx_tasks_date ON tasks(task_date);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_parent ON tasks(parent_task_id);
```

### 12.2 `tags` Table

```sql
CREATE TABLE tags (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL UNIQUE,
  color_argb INTEGER,
  created_at TEXT NOT NULL
);
```

### 12.3 `daily_summaries` Table

```sql
CREATE TABLE daily_summaries (
  task_date TEXT PRIMARY KEY NOT NULL,       -- yyyy-MM-dd
  total_scheduled INTEGER NOT NULL DEFAULT 0,
  total_completed INTEGER NOT NULL DEFAULT 0,
  total_duration_planned INTEGER NOT NULL DEFAULT 0,   -- minutes
  total_duration_completed INTEGER NOT NULL DEFAULT 0, -- minutes
  productivity_score REAL,                   -- 0.0–100.0 or null
  tag_breakdown TEXT NOT NULL DEFAULT '{}'   -- JSON: {tagName: minutes}
);
```

### 12.4 Schema Version History

| Version | Changes |
|---|---|
| 1 | Initial schema with tasks, tags, daily_summaries |
| 2 | Added `tasks.graphicImage` column |
| 3 | Added `goals` table + `tasks.goalId` column |
| 4 | Added `goals.updatedAt` column (last-write-wins sync support) |
| 5 | Added `deleted_tasks` tombstone table for delete sync |
| 6 | Rolling window cleanup: deletes old generated recurring instances (pending/uncompleted only) |

---

## 13. UI Design System

### 13.1 Colour Palette

```dart
class AppColors {
  // Brand
  static const primary = Color(0xFF5B5FEF);      // Indigo
  static const primaryDark = Color(0xFF3D41CF);
  static const accent = Color(0xFF00D4AA);        // Teal accent

  // Surface (Dark theme)
  static const surface = Color(0xFF13131A);
  static const surfaceElevated = Color(0xFF1E1E2A);
  static const surfaceHighest = Color(0xFF2A2A3A);

  // Semantic
  static const success = Color(0xFF22C77A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF60A5FA);

  // Text
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF9090A8);
  static const textDisabled = Color(0xFF505065);

  // Timeline
  static const timelineHourLine = Color(0xFF2A2A3A);
  static const timelineCurrentTime = Color(0xFF5B5FEF);
}
```

### 13.2 Typography Scale

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `displayLarge` | `Outfit` | 32sp | Bold | Onboarding headlines |
| `headlineMedium` | `Outfit` | 24sp | SemiBold | Screen titles |
| `titleLarge` | `Outfit` | 20sp | SemiBold | Section headers |
| `titleMedium` | `Inter` | 16sp | Medium | Task card titles |
| `bodyLarge` | `Inter` | 16sp | Regular | Descriptions |
| `bodyMedium` | `Inter` | 14sp | Regular | Body copy |
| `labelSmall` | `Inter` | 11sp | Medium | Timeline hour labels |

Google Fonts used: **Outfit** (display/brand) + **Inter** (body/UI).

### 13.3 Spacing System (4dp grid)

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

### 13.4 Animation Tokens

| Animation | Duration | Curve |
|---|---|---|
| Screen transition | 300ms | `easeInOutCubic` |
| Task card appear | 250ms | `easeOutBack` |
| Completion sweep | 400ms | `easeInOutQuart` |
| Time indicator move | 800ms | `linear` (per 30s tick) |
| FAB expand | 200ms | `easeOutCubic` |

### 13.5 Task Completion Animation

When a user marks a task as done, the following animation sequence plays:
1. A green checkmark **draws itself** in 200ms (path animation)
2. The task card **slides** 12dp to the right and **fades** its accent colour to greyed state in 300ms
3. A subtle **haptic** vibration fires (medium impact)
4. The card **strikethrough** animation writes across the title text in 200ms

---

## 14. Error Handling Strategy

### 14.1 Error Classification

| Category | Handling |
|---|---|
| Database errors | Caught in repository impl → wrapped in `DatabaseFailure` → surfaced via `AsyncError` state in provider → displayed via error widget |
| Notification scheduling errors | Logged silently; task is still saved; user is notified in settings screen |
| Validation errors | Real-time field-level error messages on task form |
| Navigation errors | Redirected to home screen with generic error snackbar |

### 14.2 Error UI
- `AsyncValue.error` states on providers render `AppErrorWidget` with a retry button
- Empty states use illustrated `AppEmptyStateWidget` with a descriptive call-to-action
- Database fatal errors show a full-screen error with a "Contact Support" button

---

## 15. Testing Strategy

### 15.1 Unit Tests (domain + data layers)

```
test/
├── features/
│   ├── task_stack/
│   │   ├── domain/
│   │   │   ├── create_task_usecase_test.dart
│   │   │   ├── complete_task_usecase_test.dart
│   │   │   └── generate_repeat_instances_test.dart
│   │   └── data/
│   │       └── task_repository_impl_test.dart  (uses in-memory SQLite)
│   └── analytics/
│       └── domain/
│           ├── productivity_score_test.dart
│           └── get_daily_analytics_usecase_test.dart
└── core/
    └── utils/
        └── date_utils_test.dart
```

Target: **≥ 70% coverage** on domain and data layers.

### 15.2 Widget Tests (presentation layer)

- `TaskCardWidget` — Tests all three status states render correctly
- `TimelineWidget` — Tests scroll-to-now initialisation
- `TaskFormScreen` — Tests validation states and form submission
- `AnalyticsScreen` — Tests tab switching and empty state rendering

### 15.3 Integration Tests

- Full happy-path: Create task → View on timeline → Mark as done → Verify in analytics
- Recurrence: Create daily task → Verify next-day instance exists
- Notification: Create task with notification → Verify `flutter_local_notifications` schedule call is made

Run with: `flutter test integration_test/`

---

## 16. Deployment & Build Strategy

### 16.1 Flavours
TaskStack uses Flutter flavours:
- **dev** — Debug builds, verbose logging, in-memory DB option
- **staging** — Profile builds, real SQLite, test notification IDs
- **production** — Release builds, optimised, obfuscated

### 16.2 Build Commands

```bash
# Android release
flutter build apk --flavor production --release --obfuscate --split-debug-info=build/debug-info

# iOS release
flutter build ipa --flavor production --release --obfuscate --split-debug-info=build/debug-info
```

### 16.3 CI/CD Pipeline (GitHub Actions)

```yaml
stages:
  - Lint & Format check (flutter analyze, dart format --set-exit-if-changed)
  - Unit tests (flutter test)
  - Widget tests
  - Build Android APK (staging)
  - Build iOS IPA (staging)
  - Integration tests on emulator
  - Deploy to Firebase App Distribution (staging)
  - (Manual gate) → Deploy to Play Store / App Store (production)
```

### 16.4 Versioning
Format: `MAJOR.MINOR.PATCH+BUILD`  
Example: `1.0.0+1` → `1.0.1+2` → `1.1.0+3`

Versioning is defined in `pubspec.yaml` and bumped automatically by the CI pipeline on tagged releases.

---

*End of SDD Document — TaskStack v1.0*
