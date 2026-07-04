class SessionEntity {
  final String id;
  final String personId;
  final String foodId;
  final DateTime date;
  final int targetLevel;
  final String? activity;
  final int? achievedLevel;
  final String? achievedActivity;
  final String? notes;

  const SessionEntity({
    required this.id,
    required this.personId,
    required this.foodId,
    required this.date,
    required this.targetLevel,
    this.activity,
    this.achievedLevel,
    this.achievedActivity,
    this.notes,
  });

  bool get isCompleted => achievedLevel != null;

  SessionEntity copyWith({
    String? id,
    String? personId,
    String? foodId,
    DateTime? date,
    int? targetLevel,
    String? activity,
    int? achievedLevel,
    String? achievedActivity,
    String? notes,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      foodId: foodId ?? this.foodId,
      date: date ?? this.date,
      targetLevel: targetLevel ?? this.targetLevel,
      activity: activity ?? this.activity,
      achievedLevel: achievedLevel ?? this.achievedLevel,
      achievedActivity: achievedActivity ?? this.achievedActivity,
      notes: notes ?? this.notes,
    );
  }
}
