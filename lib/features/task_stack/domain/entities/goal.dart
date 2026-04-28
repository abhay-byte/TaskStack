enum GoalType { project, habit, noTime }

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.type = GoalType.project,
    this.durationHours,
    this.iconId,
    this.graphicImage,
    this.colorArgb,
    this.isGoal = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final GoalType type;
  final int? durationHours;
  final String? iconId;
  final String? graphicImage;
  final int? colorArgb;
  final bool isGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal copyWith({
    String? id,
    String? title,
    GoalType? type,
    int? durationHours,
    String? iconId,
    String? graphicImage,
    int? colorArgb,
    bool? isGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      durationHours: durationHours ?? this.durationHours,
      iconId: iconId ?? this.iconId,
      graphicImage: graphicImage ?? this.graphicImage,
      colorArgb: colorArgb ?? this.colorArgb,
      isGoal: isGoal ?? this.isGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
