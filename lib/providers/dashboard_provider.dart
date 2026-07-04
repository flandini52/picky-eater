import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/food_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/weekly_goal_repository.dart';
import '../models/food_entity.dart';
import 'database_provider.dart';

// --- Repository providers ---

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(ref.watch(databaseProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(databaseProvider));
});

final weeklyGoalRepositoryProvider = Provider<WeeklyGoalRepository>((ref) {
  return WeeklyGoalRepository(ref.watch(databaseProvider));
});

// --- Domain models ---

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

class DashboardNotifier extends FamilyAsyncNotifier<DashboardData, String> {
  @override
  Future<DashboardData> build(String personId) async {
    return _load(personId);
  }

  Future<DashboardData> _load(String personId) async {
    final foodRepo = ref.read(foodRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final weeklyGoalRepo = ref.read(weeklyGoalRepositoryProvider);

    final weeklyGoal = await weeklyGoalRepo.getWeeklyGoal(personId);
    final sessionsThisWeek = await sessionRepo.getSessionsThisWeek(personId);
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

final dashboardProvider =
    AsyncNotifierProvider.family<DashboardNotifier, DashboardData, String>(
      DashboardNotifier.new,
    );
