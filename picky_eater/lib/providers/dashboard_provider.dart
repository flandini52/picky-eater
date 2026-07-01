import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/food_repository.dart';
import '../repositories/session_repository.dart';
import '../models/food_entity.dart';
import '../database/app_database.dart';
import '../main.dart';

// --- Repository providers ---

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(database);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(database);
});

// --- Domain model per la dashboard ---

class FoodProgress {
  final FoodEntity food;
  final int sessionCount;

  const FoodProgress({required this.food, required this.sessionCount});
}

class DashboardData {
  final List<FoodProgress> progress;
  final int weeklyGoal;
  final int sessionsThisWeek;

  const DashboardData({
    required this.progress,
    required this.weeklyGoal,
    required this.sessionsThisWeek,
  });
}

// --- AsyncNotifierProvider.family: riceve personId come parametro ---

class DashboardNotifier
    extends FamilyAsyncNotifier<DashboardData, String> {
  @override
  Future<DashboardData> build(String personId) async {
    return _load(personId);
  }

  Future<DashboardData> _load(String personId) async {
    final foodRepo = ref.read(foodRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);

    final weeklyGoal = await database.getWeeklyGoal(personId);
    final sessionsThisWeek =
        await sessionRepo.getSessionsThisWeek(personId);
    final foods = await foodRepo.getFoodsByPerson(personId);

    final progress = await Future.wait(
      foods.map((food) async {
        final count = await foodRepo.getSessionCountForFood(food.id);
        return FoodProgress(food: food, sessionCount: count);
      }),
    );

    return DashboardData(
      progress: progress,
      weeklyGoal: weeklyGoal,
      sessionsThisWeek: sessionsThisWeek,
    );
  }

  Future<void> refresh() async {
    final personId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(personId));
  }
}

final dashboardProvider = AsyncNotifierProvider.family<DashboardNotifier,
    DashboardData, String>(
  DashboardNotifier.new,
);