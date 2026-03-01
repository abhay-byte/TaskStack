import 'package:flutter/material.dart' show TimeOfDay;

enum RecurrenceType { none, repeatToday, daily, weekly, custom }

enum TaskStatus { pending, done }

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.purpose,
    this.iconId,
    this.graphicImage,
    this.colorArgb,
    this.tags = const [],
    this.startMinutes,
    this.durationMinutes,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceRule,
    this.repeatIntervalMinutes,
    this.notificationEnabled = true,
    this.notificationOffsetMinutes = 5,
    this.status = TaskStatus.pending,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.parentTaskId,
    required this.taskDate,
  });

  final String id;
  final String title;
  final String? description;
  final String? purpose;
  final String? iconId;
  final String? graphicImage;
  final int? colorArgb;
  final List<String> tags;
  final int? startMinutes; // minutes from midnight
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
  final DateTime taskDate; // calendar day

  bool get isDone => status == TaskStatus.done;

  /// Returns a list of `DateTime.weekday` integers (1=Mon, 7=Sun) if this
  /// task repeats on custom days.
  List<int> get customRecurrenceDays {
    if (recurrenceType != RecurrenceType.custom ||
        recurrenceRule == null ||
        recurrenceRule!.isEmpty) {
      return [];
    }
    return recurrenceRule!
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e >= 1 && e <= 7)
        .toList();
  }

  /// Whether the task is currently within its active time window.
  bool isInProgress(DateTime now) {
    if (startMinutes == null) return false;
    final todayMinutes = now.hour * 60 + now.minute;
    final end = startMinutes! + (durationMinutes ?? 30);
    return todayMinutes >= startMinutes! && todayMinutes < end;
  }

  TimeOfDay? get startTime {
    if (startMinutes == null) return null;
    return TimeOfDay(hour: startMinutes! ~/ 60, minute: startMinutes! % 60);
  }

  Task copyWith({
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
    String? recurrenceRule,
    int? repeatIntervalMinutes,
    bool? notificationEnabled,
    int? notificationOffsetMinutes,
    TaskStatus? status,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentTaskId,
    DateTime? taskDate,
  }) {
    return Task(
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
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationOffsetMinutes:
          notificationOffsetMinutes ?? this.notificationOffsetMinutes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      taskDate: taskDate ?? this.taskDate,
    );
  }
}
