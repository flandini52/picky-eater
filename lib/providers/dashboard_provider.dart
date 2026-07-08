import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_entity.dart';
import '../repositories/food_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/weekly_goal_repository.dart';
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

class FoodProgressSummary {
  final String foodId;
  final String foodName;
  final String category;
  final int currentLevel;
  final int previousLevel;
  final DateTime? lastSessionDate;

  const FoodProgressSummary({
    required this.foodId,
    required this.foodName,
    required this.category,
    required this.currentLevel,
    required this.previousLevel,
    required this.lastSessionDate,
  });
}

class WeeklySessionCount {
  final DateTime weekStart;
  final int count;

  const WeeklySessionCount({required this.weekStart, required this.count});
}

class DashboardData {
  final int weeklyGoal;
  final int sessionsThisWeek;
  final int sessionsThisMonth;
  final int totalSessionsAllTime;
  final int totalFoodsTracked;
  final int totalSafeFoods;
  final List<FoodProgressSummary> recentlyImproved;
  final List<FoodProgressSummary> stagnant;
  final List<WeeklySessionCount> weeklyTrend;

  const DashboardData({
    required this.weeklyGoal,
    required this.sessionsThisWeek,
    required this.sessionsThisMonth,
    required this.totalSessionsAllTime,
    required this.totalFoodsTracked,
    required this.totalSafeFoods,
    required this.recentlyImproved,
    required this.stagnant,
    required this.weeklyTrend,
  });
}

const _recentWindow = Duration(days: 30);
const _stagnantThreshold = Duration(days: 14);
const _weeklyTrendWeeks = 8;

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
    final sessionsThisMonth = await sessionRepo.getSessionsThisMonth(personId);
    final completedSessions = await sessionRepo.getCompletedSessionsForPerson(
      personId,
    );
    final sosFoods = await foodRepo.getSosFoodsByPerson(personId);
    final safeFoods = await foodRepo.getSafeFoodsByPerson(personId);

    final now = DateTime.now();
    final recentCutoff = now.subtract(_recentWindow);
    final stagnantCutoff = now.subtract(_stagnantThreshold);

    final recentlyImproved = <FoodProgressSummary>[];
    final stagnant = <FoodProgressSummary>[];

    await Future.wait(
      sosFoods.map((food) async {
        final foodSessions = await sessionRepo.getCompletedSessionsForFood(
          food.id,
        );
        final lastSessionDate = foodSessions.isEmpty
            ? null
            : foodSessions.last.date;

        final sessionsBeforeWindow = foodSessions
            .where((s) => s.date.isBefore(recentCutoff))
            .toList();
        final sessionsInWindow = foodSessions
            .where((s) => !s.date.isBefore(recentCutoff))
            .toList();
        final previousLevel = sessionsBeforeWindow.isEmpty
            ? 0
            : sessionsBeforeWindow.last.achievedLevel!;

        final improvedRecently = sessionsInWindow.any(
          (s) => s.achievedLevel! > previousLevel,
        );
        if (improvedRecently) {
          recentlyImproved.add(
            FoodProgressSummary(
              foodId: food.id,
              foodName: food.name,
              category: food.category,
              currentLevel: food.currentLevel,
              previousLevel: previousLevel,
              lastSessionDate: lastSessionDate,
            ),
          );
        }

        if (lastSessionDate == null ||
            lastSessionDate.isBefore(stagnantCutoff)) {
          stagnant.add(
            FoodProgressSummary(
              foodId: food.id,
              foodName: food.name,
              category: food.category,
              currentLevel: food.currentLevel,
              previousLevel: previousLevel,
              lastSessionDate: lastSessionDate,
            ),
          );
        }
      }),
    );

    final weeklyTrend = _buildWeeklyTrend(completedSessions, now);

    return DashboardData(
      weeklyGoal: weeklyGoal,
      sessionsThisWeek: sessionsThisWeek,
      sessionsThisMonth: sessionsThisMonth,
      totalSessionsAllTime: completedSessions.length,
      totalFoodsTracked: sosFoods.length,
      totalSafeFoods: safeFoods.length,
      recentlyImproved: recentlyImproved,
      stagnant: stagnant,
      weeklyTrend: weeklyTrend,
    );
  }

  List<WeeklySessionCount> _buildWeeklyTrend(
    List<SessionEntity> completedSessions,
    DateTime now,
  ) {
    final currentMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final weeks = <WeeklySessionCount>[];
    for (int i = _weeklyTrendWeeks - 1; i >= 0; i--) {
      final weekStart = currentMonday.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final count = completedSessions
          .where((s) => !s.date.isBefore(weekStart) && s.date.isBefore(weekEnd))
          .length;
      weeks.add(WeeklySessionCount(weekStart: weekStart, count: count));
    }
    return weeks;
  }

  Future<void> refresh() async {
    final personId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(personId));
  }

  Future<void> updateWeeklyGoal(String personId, int newGoal) async {
    final repo = ref.read(weeklyGoalRepositoryProvider);
    await repo.setWeeklyGoal(personId, newGoal);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(personId));
  }
}

final dashboardProvider =
    AsyncNotifierProvider.family<DashboardNotifier, DashboardData, String>(
      DashboardNotifier.new,
    );
