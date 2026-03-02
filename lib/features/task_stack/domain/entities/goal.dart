enum GoalType { project, habit, noTime }

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.type = GoalType.project,
    this.durationHours,
    required this.createdAt,
  });

  final String id;
  final String title;
  final GoalType type;
  final int? durationHours;
  final DateTime createdAt;

  Goal copyWith({
    String? id,
    String? title,
    GoalType? type,
    int? durationHours,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      durationHours: durationHours ?? this.durationHours,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
