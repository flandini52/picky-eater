import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/dashboard_provider.dart';
import 'achivements_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final Person person;

  const DashboardScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider(person.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Progressi di ${person.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Traguardi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AchievementsScreen(person: person),
                ),
              );
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.orange)),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardProvider(person.id).notifier).refresh(),
          color: Colors.orange,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WeeklyGoalCard(
                sessionsThisWeek: data.sessionsThisWeek,
                weeklyGoal: data.weeklyGoal,
              ),
              const SizedBox(height: 20),
              if (data.progress.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Nessun alimento ancora.\nVai su Alimenti per aggiungerne uno!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: data.progress.length,
                  itemBuilder: (context, index) {
                    return _FoodProgressCard(item: data.progress[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  final int sessionsThisWeek;
  final int weeklyGoal;

  const _WeeklyGoalCard({
    required this.sessionsThisWeek,
    required this.weeklyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Obiettivo settimanale',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (sessionsThisWeek / weeklyGoal).clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$sessionsThisWeek di $weeklyGoal sessioni questa settimana',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FoodProgressCard extends StatelessWidget {
  final FoodProgress item;

  const _FoodProgressCard({required this.item});

  Color _levelColor(int level) {
    switch (level) {
      case 0:
        return Colors.red.shade300;
      case 1:
        return Colors.orange.shade300;
      case 2:
        return Colors.yellow.shade600;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.blue.shade300;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = item.food;
    final level = ExposureLevel.values[food.currentLevel];
    final color = _levelColor(food.currentLevel);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.category.emoji,
                style: const TextStyle(fontSize: 36)),
            Text(
              food.name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (food.currentLevel + 1) / 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level.label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.event_note,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${item.sessionCount} sessioni',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}