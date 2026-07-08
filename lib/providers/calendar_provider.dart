import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/badge_type.dart';
import '../models/food_entity.dart';
import '../models/session_entity.dart';
import '../repositories/badge_repository.dart';
import 'database_provider.dart';
import 'dashboard_provider.dart';
import 'notification_provider.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(ref.watch(databaseProvider));
});

/// Marker di sessione per un giorno del calendario — solo i dati necessari
/// a colorare i puntini (`calendar_screen.dart`), non l'intera sessione.
class SessionMarker {
  final bool isCompleted;
  final String? foodCategory;

  const SessionMarker({required this.isCompleted, this.foodCategory});
}

class CalendarState {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<SessionEntity> sessionsForDay;
  final List<FoodEntity> foods;
  final Map<DateTime, List<SessionMarker>> markers;

  const CalendarState({
    required this.focusedDay,
    this.selectedDay,
    this.sessionsForDay = const [],
    this.foods = const [],
    this.markers = const {},
  });

  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    List<SessionEntity>? sessionsForDay,
    List<FoodEntity>? foods,
    Map<DateTime, List<SessionMarker>>? markers,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      sessionsForDay: sessionsForDay ?? this.sessionsForDay,
      foods: foods ?? this.foods,
      markers: markers ?? this.markers,
    );
  }
}

class CalendarNotifier extends FamilyAsyncNotifier<CalendarState, String> {
  @override
  Future<CalendarState> build(String personId) async {
    final foods = await ref
        .read(foodRepositoryProvider)
        .getFoodsByPerson(personId);
    final now = DateTime.now();
    final markers = await _loadMarkers(personId, now, foods);
    return CalendarState(focusedDay: now, foods: foods, markers: markers);
  }

  /// Carica i marker (pianificato/completato + categoria alimento) per tutte
  /// le sessioni del mese di [month], da mostrare come puntini colorati sotto
  /// le date del calendario.
  Future<void> loadMarkersForMonth(String personId, DateTime month) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final markers = await _loadMarkers(personId, month, current.foods);
    state = AsyncData(current.copyWith(markers: markers));
  }

  Future<Map<DateTime, List<SessionMarker>>> _loadMarkers(
    String personId,
    DateTime month,
    List<FoodEntity> foods,
  ) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final firstOfNextMonth = DateTime(month.year, month.month + 1, 1);

    final sessions = await ref
        .read(sessionRepositoryProvider)
        .getSessionsByPersonAndDateRange(personId, firstDay, firstOfNextMonth);

    final markers = <DateTime, List<SessionMarker>>{};
    for (final session in sessions) {
      final day = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      String? category;
      for (final food in foods) {
        if (food.id == session.foodId) {
          category = food.category;
          break;
        }
      }
      markers
          .putIfAbsent(day, () => [])
          .add(
            SessionMarker(
              isCompleted: session.isCompleted,
              foodCategory: category,
            ),
          );
    }
    return markers;
  }

  /// Ricarica la lista completa (SOS + safe food) dopo l'inserimento o la
  /// modifica di un alimento. Usa [getFoodsByPerson] e non
  /// [FoodRepository.getSosFoodsByPerson]: `state.foods` deve restare
  /// completa perché `calendar_screen.dart` la usa anche per il lookup
  /// nome-alimento delle sessioni collegate a cibi diventati safe food nel
  /// frattempo — il filtro SOS-only va fatto solo al punto d'uso
  /// (`_showAddSession`).
  Future<void> refreshFoods(String personId) async {
    final foods = await ref
        .read(foodRepositoryProvider)
        .getFoodsByPerson(personId);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(foods: foods));
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
    required String personName,
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

    // Reschedula solo la notifica della persona corrente
    final notificationState = await ref.read(notificationProvider.future);
    if (notificationState.isEnabled && notificationState.permissionGranted) {
      await ref
          .read(notificationProvider.notifier)
          .rescheduleForPerson(personId: personId, personName: personName);
    }

    return badges;
  }
}

final calendarProvider =
    AsyncNotifierProvider.family<CalendarNotifier, CalendarState, String>(
      CalendarNotifier.new,
    );
