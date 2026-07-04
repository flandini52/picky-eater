import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/badge_type.dart';
import '../models/food_entity.dart';
import '../models/session_entity.dart';
import '../repositories/badge_repository.dart';
import 'database_provider.dart';
import 'dashboard_provider.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(ref.watch(databaseProvider));
});

class CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<SessionEntity> sessionsForDay;
  final List<FoodEntity> foods;

  const CalendarState({
    required this.focusedDay,
    this.selectedDay,
    this.sessionsForDay = const [],
    this.foods = const [],
  });

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    List<SessionEntity>? sessionsForDay,
    List<FoodEntity>? foods,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      sessionsForDay: sessionsForDay ?? this.sessionsForDay,
      foods: foods ?? this.foods,
    );
  }
}

class CalendarNotifier extends FamilyAsyncNotifier<CalendarState, String> {
  @override
  Future<CalendarState> build(String personId) async {
    final foods = await ref
        .read(foodRepositoryProvider)
        .getFoodsByPerson(personId);
    return CalendarState(focusedDay: DateTime.now(), foods: foods);
  }

  Future<void> selectDay(String personId, DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final sessions = await ref
        .read(sessionRepositoryProvider)
        .getSessionsByPersonAndDate(personId, normalized);

    final current =
        state.valueOrNull ?? CalendarState(focusedDay: DateTime.now());
    state = AsyncData(
      current.copyWith(
        selectedDay: day,
        focusedDay: day,
        sessionsForDay: sessions,
      ),
    );
  }

  Future<void> refreshSessionsForDay(String personId) async {
    final current = state.valueOrNull;
    if (current?.selectedDay == null) return;
    final normalized = DateTime(
      current!.selectedDay!.year,
      current.selectedDay!.month,
      current.selectedDay!.day,
    );
    final sessions = await ref
        .read(sessionRepositoryProvider)
        .getSessionsByPersonAndDate(personId, normalized);
    state = AsyncData(current.copyWith(sessionsForDay: sessions));
  }

  Future<void> addSession({
    required String personId,
    required String foodId,
    required DateTime date,
    required int targetLevel,
    String? activity,
  }) async {
    await ref
        .read(sessionRepositoryProvider)
        .insertSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          personId: personId,
          foodId: foodId,
          date: date,
          targetLevel: targetLevel,
          activity: activity,
        );
    await refreshSessionsForDay(personId);
  }

  Future<List<BadgeType>> completeSession({
    required String personId,
    required String sessionId,
    required String foodId,
    required int currentFoodLevel,
    required int achievedLevel,
    String? achievedActivity,
    String? notes,
  }) async {
    await ref
        .read(sessionRepositoryProvider)
        .completeSession(
          sessionId: sessionId,
          achievedLevel: achievedLevel,
          achievedActivity: achievedActivity,
          notes: notes,
        );
    if (achievedLevel > currentFoodLevel) {
      await ref
          .read(foodRepositoryProvider)
          .updateFoodLevel(foodId, achievedLevel);
      final current = state.valueOrNull;
      if (current != null) {
        final updatedFoods = current.foods.map((f) {
          if (f.id == foodId) return f.copyWith(currentLevel: achievedLevel);
          return f;
        }).toList();
        state = AsyncData(current.copyWith(foods: updatedFoods));
      }
    }
    final badges = await ref
        .read(badgeRepositoryProvider)
        .checkAndUnlockBadges(personId, foodId, achievedLevel);
    await refreshSessionsForDay(personId);
    return badges;
  }
}

final calendarProvider =
    AsyncNotifierProvider.family<CalendarNotifier, CalendarState, String>(
      CalendarNotifier.new,
    );
