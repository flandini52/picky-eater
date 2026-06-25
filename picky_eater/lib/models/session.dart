import '../database/app_database.dart';

class Session {
  final String id;
  final DateTime date;
  final Food food;
  final ExposureLevel targetLevel;
  ExposureLevel? achievedLevel;
  String? notes;
  bool get isCompleted => achievedLevel != null;

  Session({
    required this.id,
    required this.date,
    required this.food,
    required this.targetLevel,
    this.achievedLevel,
    this.notes,
  });
}