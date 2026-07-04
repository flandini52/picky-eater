import '../database/app_database.dart';
import '../models/session_entity.dart';
import 'package:drift/drift.dart';

class SessionRepository {
  final AppDatabase _db;

  SessionRepository(this._db);

  // Mapper Drift → dominio
  SessionEntity _toEntity(Session session) => SessionEntity(
    id: session.id,
    personId: session.personId,
    foodId: session.foodId,
    date: session.date,
    targetLevel: session.targetLevel,
    activity: session.activity,
    achievedLevel: session.achievedLevel,
    achievedActivity: session.achievedActivity,
    notes: session.notes,
  );

  Future<List<SessionEntity>> getSessionsByPerson(String personId) async {
    final sessions = await _db.getSessionsByPerson(personId);
    return sessions.map(_toEntity).toList();
  }

  Future<List<SessionEntity>> getSessionsByPersonAndDate(
    String personId,
    DateTime date,
  ) async {
    final sessions = await _db.getSessionsByPersonAndDate(personId, date);
    return sessions.map(_toEntity).toList();
  }

  Future<List<SessionEntity>> getCompletedSessionsForFood(String foodId) async {
    final sessions = await _db.getCompletedSessionsForFood(foodId);
    return sessions.map(_toEntity).toList();
  }

  Future<int> getSessionsThisWeek(String personId) =>
      _db.getSessionsThisWeek(personId);

  Future<void> insertSession({
    required String id,
    required String personId,
    required String foodId,
    required DateTime date,
    required int targetLevel,
    String? activity,
  }) => _db.insertSession(
    SessionsCompanion.insert(
      id: id,
      personId: personId,
      foodId: foodId,
      date: date,
      targetLevel: targetLevel,
      activity: Value(activity),
    ),
  );

  Future<void> completeSession({
    required String sessionId,
    required int achievedLevel,
    String? achievedActivity,
    String? notes,
  }) => _db.completeSession(sessionId, achievedLevel, achievedActivity, notes);
}
