import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskstack/database/app_database.dart';
import 'package:taskstack/database/daos/task_dao.dart';
import 'package:taskstack/features/task_stack/domain/entities/task.dart';
import 'package:taskstack/features/task_stack/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._dao);
  final TaskDao _dao;

  String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    return _dao
        .watchTasksForDate(_dateString(date))
        .map((rows) => rows.map(_rowToTask).toList());
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final row = await _dao.getTaskById(id);
    return row == null ? null : _rowToTask(row);
  }

  @override
  Future<void> insertTask(Task task) => _dao.insertTask(_taskToCompanion(task));

  @override
  Future<void> insertTasks(List<Task> tasks) =>
      _dao.insertTasks(tasks.map(_taskToCompanion).toList());

  @override
  Future<void> updateTask(Task task) => _dao.updateTask(_taskToCompanion(task));

  @override
  Future<void> deleteTask(String id) async {
    await _dao.recordTaskDeletions([id]);
    await _dao.deleteTaskById(id);
  }

  @override
  Future<void> deleteRecurringFamily(String parentId) async {
    final ids = await _dao.getRecurringFamilyTaskIds(parentId);
    await _dao.recordTaskDeletions(ids);
    await _dao.deleteRecurringFamily(parentId);
  }

  @override
  Future<void> deleteRecurringTasksFromDate(
    String parentId,
    DateTime date, {
    bool inclusive = true,
  }) async {
    final dateStr = _dateString(date);
    final ids = await _dao.getRecurringTaskIdsFromDate(
      parentId,
      dateStr,
      inclusive: inclusive,
    );
    await _dao.recordTaskDeletions(ids);
    await _dao.deleteRecurringTasksFromDate(
      parentId,
      dateStr,
      inclusive: inclusive,
    );
  }

  @override
  Future<List<Task>> getTasksInRange(DateTime from, DateTime to) async {
    final rows = await _dao.getTasksInRange(_dateString(from), _dateString(to));
    return rows.map(_rowToTask).toList();
  }

  @override
  Future<void> updateStatus(
    String id, {
    required String status,
    DateTime? completedAt,
  }) => _dao.updateStatus(id, status: status, completedAt: completedAt);

  // ── Mappers ──────────────────────────────────────────────────────────────

  Task _rowToTask(TasksTableData row) {
    return Task(
      id: row.id,
      title: row.title,
      description: row.description,
      purpose: row.purpose,
      iconId: row.iconId,
      graphicImage: row.graphicImage,
      colorArgb: row.colorArgb,
      tags: (jsonDecode(row.tagsJson) as List).cast<String>(),
      startMinutes: row.startMinutes,
      durationMinutes: row.durationMinutes,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == row.recurrenceType,
        orElse: () => RecurrenceType.none,
      ),
      recurrenceRule: row.recurrenceRule,
      repeatIntervalMinutes: row.repeatIntervalMinutes,
      notificationEnabled: row.notificationEnabled,
      notificationOffsetMinutes: row.notificationOffsetMinutes,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => TaskStatus.pending,
      ),
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      parentTaskId: row.parentTaskId,
      goalId: row.goalId,
      taskDate: DateTime.parse(row.taskDate),
    );
  }

  TasksTableCompanion _taskToCompanion(Task task) {
    return TasksTableCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      purpose: Value(task.purpose),
      iconId: Value(task.iconId),
      graphicImage: Value(task.graphicImage),
      colorArgb: Value(task.colorArgb),
      tagsJson: Value(jsonEncode(task.tags)),
      startMinutes: Value(task.startMinutes),
      durationMinutes: Value(task.durationMinutes),
      recurrenceType: Value(task.recurrenceType.name),
      recurrenceRule: Value(task.recurrenceRule),
      repeatIntervalMinutes: Value(task.repeatIntervalMinutes),
      notificationEnabled: Value(task.notificationEnabled),
      notificationOffsetMinutes: Value(task.notificationOffsetMinutes),
      status: Value(task.status.name),
      completedAt: Value(task.completedAt),
      createdAt: Value(task.createdAt),
      updatedAt: Value(task.updatedAt),
      parentTaskId: Value(task.parentTaskId),
      goalId: Value(task.goalId),
      taskDate: Value(_dateString(task.taskDate)),
    );
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(taskDaoProvider));
});
