import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/data/repositories/task_repository_impl.dart';
import 'package:taskstack/features/task_stack/domain/usecases/task_usecases.dart';
import 'package:taskstack/features/notifications/notification_scheduler.dart';
import 'package:taskstack/features/sync/domain/repositories/sync_repository.dart';
import 'package:taskstack/features/sync/data/repositories/sync_repository_impl.dart';

// ── Date Providers ────────────────────────────────────────────────────────

/// The currently viewed date on the stack.
final selectedStackDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ── Task Stream ───────────────────────────────────────────────────────────

/// Stream of tasks for a given calendar date.
final tasksForDateProvider = StreamProvider.family<List<Task>, DateTime>((
  ref,
  date,
) {
  return ref.watch(taskRepositoryProvider).watchTasksForDate(date);
});

/// Sorted tasks for the currently selected date.
final sortedTasksProvider = Provider<List<Task>>((ref) {
  final date = ref.watch(selectedStackDateProvider);
  final async = ref.watch(tasksForDateProvider(date));
  final tasks = async.value ?? [];
  return [...tasks]..sort((a, b) {
    if (a.startMinutes == null && b.startMinutes == null) return 0;
    if (a.startMinutes == null) return 1;
    if (b.startMinutes == null) return -1;
    return a.startMinutes!.compareTo(b.startMinutes!);
  });
});

/// Scheduled tasks only (have a start time).
final scheduledTasksProvider = Provider<List<Task>>((ref) {
  return ref
      .watch(sortedTasksProvider)
      .where((t) => t.startMinutes != null)
      .toList();
});

/// Unscheduled tasks (no start time).
final unscheduledTasksProvider = Provider<List<Task>>((ref) {
  return ref
      .watch(sortedTasksProvider)
      .where((t) => t.startMinutes == null)
      .toList();
});

// ── Use Case Providers ────────────────────────────────────────────────────

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  return CreateTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
  );
});

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>((ref) {
  return UpdateTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
  );
});

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  return DeleteTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(syncRepositoryProvider),
  );
});

final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(ref.watch(taskRepositoryProvider));
});

final duplicateTaskUseCaseProvider = Provider<DuplicateTaskUseCase>((ref) {
  return DuplicateTaskUseCase(ref.watch(taskRepositoryProvider));
});

// ── Task Form State ───────────────────────────────────────────────────────

class TaskFormState {
  const TaskFormState({
    this.id = '',
    this.title = '',
    this.description = '',
    this.purpose = '',
    this.iconId,
    this.graphicImage,
    this.colorArgb,
    this.tags = const [],
    this.startMinutes,
    this.durationMinutes = 30,
    this.recurrenceType = RecurrenceType.none,
    this.repeatIntervalMinutes = 60,
    this.customRecurrenceDays = const [],
    this.notificationEnabled = true,
    this.notificationOffsetMinutes = 5,
    this.taskDate,
    this.parentTaskId,
    this.goalId,
    this.createdAt,
    this.isSaving = false,
    this.error,
  });

  final String id;
  final String title;
  final String description;
  final String purpose;
  final String? iconId;
  final String? graphicImage;
  final int? colorArgb;
  final List<String> tags;
  final int? startMinutes;
  final int durationMinutes;
  final RecurrenceType recurrenceType;
  final int repeatIntervalMinutes;
  final List<int> customRecurrenceDays;
  final bool notificationEnabled;
  final int notificationOffsetMinutes;
  final DateTime? taskDate;
  final String? parentTaskId;
  final String? goalId;
  final DateTime? createdAt;
  final bool isSaving;
  final String? error;

  bool get isValid => title.trim().isNotEmpty;

  TaskFormState copyWith({
    String? id,
    String? title,
    String? description,
    String? purpose,
    String? iconId,
    String? graphicImage,
    int? colorArgb,
    List<String>? tags,
    int? startMinutes,
    int? durationMinutes,
    RecurrenceType? recurrenceType,
    int? repeatIntervalMinutes,
    List<int>? customRecurrenceDays,
    bool? notificationEnabled,
    int? notificationOffsetMinutes,
    DateTime? taskDate,
    String? parentTaskId,
    String? goalId,
    DateTime? createdAt,
    bool? isSaving,
    String? error,
  }) {
    return TaskFormState(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      iconId: iconId ?? this.iconId,
      graphicImage: graphicImage ?? this.graphicImage,
      colorArgb: colorArgb ?? this.colorArgb,
      tags: tags ?? this.tags,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      customRecurrenceDays: customRecurrenceDays ?? this.customRecurrenceDays,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationOffsetMinutes:
          notificationOffsetMinutes ?? this.notificationOffsetMinutes,
      taskDate: taskDate ?? this.taskDate,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      goalId: goalId ?? this.goalId,
      createdAt: createdAt ?? this.createdAt,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
    );
  }
}

class TaskFormNotifier extends Notifier<TaskFormState> {
  @override
  TaskFormState build() {
    return const TaskFormState();
  }

  CreateTaskUseCase get _create => ref.read(createTaskUseCaseProvider);
  UpdateTaskUseCase get _update => ref.read(updateTaskUseCaseProvider);
  SyncRepository get _sync => ref.read(syncRepositoryProvider);

  void loadTask(Task task) {
    state = TaskFormState(
      id: task.id,
      title: task.title,
      description: task.description ?? '',
      purpose: task.purpose ?? '',
      iconId: task.iconId,
      graphicImage: task.graphicImage,
      colorArgb: task.colorArgb,
      tags: task.tags,
      startMinutes: task.startMinutes,
      durationMinutes: task.durationMinutes ?? 30,
      recurrenceType: task.recurrenceType,
      repeatIntervalMinutes: task.repeatIntervalMinutes ?? 60,
      customRecurrenceDays: task.customRecurrenceDays,
      notificationEnabled: task.notificationEnabled,
      notificationOffsetMinutes: task.notificationOffsetMinutes,
      taskDate: task.taskDate,
      parentTaskId: task.parentTaskId,
      goalId: task.goalId,
      createdAt: task.createdAt,
    );
  }

  void updateTitle(String v) => state = state.copyWith(title: v);
  void updateDescription(String v) => state = state.copyWith(description: v);
  void updatePurpose(String v) => state = state.copyWith(purpose: v);
  void updateIconId(String? v) => state = state.copyWith(iconId: v);
  void updateGraphicImage(String? v) => state = state.copyWith(graphicImage: v);
  void updateColor(int? v) => state = state.copyWith(colorArgb: v);
  void updateTags(List<String> v) => state = state.copyWith(tags: v);
  void updateStartMinutes(int? v) => state = state.copyWith(startMinutes: v);
  void updateDuration(int v) => state = state.copyWith(durationMinutes: v);
  void updateRecurrence(RecurrenceType v) =>
      state = state.copyWith(recurrenceType: v);
  void updateRepeatInterval(int v) =>
      state = state.copyWith(repeatIntervalMinutes: v);
  void toggleCustomDay(int day) {
    final days = List<int>.from(state.customRecurrenceDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
      days.sort();
    }
    state = state.copyWith(customRecurrenceDays: days);
  }

  void updateNotificationEnabled(bool v) =>
      state = state.copyWith(notificationEnabled: v);
  void updateNotificationOffset(int v) =>
      state = state.copyWith(notificationOffsetMinutes: v);
  void updateGoalId(String? v) => state = state.copyWith(goalId: v);

  Future<bool> save(
    DateTime taskDate, {
    RecurringScope scope = RecurringScope.thisInstance,
  }) async {
    if (!state.isValid) return false;

    // Validate repeatToday overlap: repeat interval must be >= task duration
    if (state.recurrenceType == RecurrenceType.repeatToday &&
        state.repeatIntervalMinutes < state.durationMinutes) {
      state = state.copyWith(
        error:
            'Repeat interval (${state.repeatIntervalMinutes} min) is less than task duration (${state.durationMinutes} min) — tasks would overlap. Please increase the interval or reduce the duration.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);
    try {
      final task = Task(
        id: state.id,
        title: state.title.trim(),
        description: state.description.isEmpty ? null : state.description,
        purpose: state.purpose.isEmpty ? null : state.purpose,
        iconId: state.iconId,
        graphicImage: state.graphicImage,
        colorArgb: state.colorArgb,
        tags: state.tags,
        startMinutes: state.startMinutes,
        durationMinutes: state.durationMinutes,
        recurrenceType: state.recurrenceType,
        recurrenceRule:
            state.recurrenceType == RecurrenceType.custom
                ? state.customRecurrenceDays.join(',')
                : null,
        repeatIntervalMinutes: state.repeatIntervalMinutes,
        notificationEnabled: state.notificationEnabled,
        notificationOffsetMinutes: state.notificationOffsetMinutes,
        createdAt: state.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        taskDate: taskDate,
        parentTaskId: state.parentTaskId,
        goalId: state.goalId,
      );
      if (state.id.isEmpty) {
        await _create.execute(task);
      } else {
        await _update.execute(task, scope: scope);
      }
      _sync.pushLocalToCloud(); // fire-and-forget cloud sync
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final taskFormProvider =
    NotifierProvider.autoDispose<TaskFormNotifier, TaskFormState>(
      TaskFormNotifier.new,
    );
