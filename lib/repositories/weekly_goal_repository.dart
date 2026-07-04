import '../database/app_database.dart';

class WeeklyGoalRepository {
  final AppDatabase _db;

  WeeklyGoalRepository(this._db);

  Future<int> getWeeklyGoal(String personId) => _db.getWeeklyGoal(personId);

  Future<void> setWeeklyGoal(String personId, int target) =>
      _db.setWeeklyGoal(personId, target);
}
