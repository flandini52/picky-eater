import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_theme.dart';
import '../core/exposure_level.dart';
import '../database/app_database.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final Person person;
  final VoidCallback? onNavigateToCalendar;

  const DashboardScreen({
    super.key,
    required this.person,
    this.onNavigateToCalendar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider(person.id));

    return Scaffold(
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardProvider(person.id).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WeeklyGoalCard(
                sessionsThisWeek: data.sessionsThisWeek,
                weeklyGoal: data.weeklyGoal,
                onEditGoal: () =>
                    _editWeeklyGoal(context, ref, data.weeklyGoal),
              ),
              const SizedBox(height: 20),
              _StatsGrid(data: data),
              const SizedBox(height: 24),
              _WeeklyTrendChart(weeklyTrend: data.weeklyTrend),
              if (data.recentlyImproved.isNotEmpty) ...[
                const SizedBox(height: 24),
                _RecentlyImprovedSection(items: data.recentlyImproved),
              ],
              if (data.stagnant.isNotEmpty) ...[
                const SizedBox(height: 24),
                _StagnantSection(
                  items: data.stagnant,
                  onPlanSession: onNavigateToCalendar,
                ),
              ],
              const SizedBox(height: 24),
              _MotivationalMessage(
                sessionsThisWeek: data.sessionsThisWeek,
                weeklyGoal: data.weeklyGoal,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editWeeklyGoal(
    BuildContext context,
    WidgetRef ref,
    int currentGoal,
  ) async {
    int target = currentGoal;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Obiettivo settimanale'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Quante sessioni vuoi fare questa settimana?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: target > 1
                            ? () => setState(() => target--)
                            : null,
                      ),
                      Text(
                        '$target',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: target < 14
                            ? () => setState(() => target++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, target),
                  child: const Text('Salva'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != currentGoal) {
      await ref
          .read(dashboardProvider(person.id).notifier)
          .updateWeeklyGoal(person.id, result);
    }
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  final int sessionsThisWeek;
  final int weeklyGoal;
  final VoidCallback onEditGoal;

  const _WeeklyGoalCard({
    required this.sessionsThisWeek,
    required this.weeklyGoal,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.salvia, AppColors.salviaDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Obiettivo settimanale',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onEditGoal,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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

class _StatsGrid extends StatelessWidget {
  final DashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        value: data.sessionsThisMonth,
        label: 'Sessioni questo mese',
        icon: Icons.event_available,
      ),
      (
        value: data.totalFoodsTracked,
        label: 'Alimenti in percorso',
        icon: Icons.restaurant,
      ),
      (value: data.totalSafeFoods, label: 'Safe foods', icon: Icons.verified),
      (
        value: data.totalSessionsAllTime,
        label: 'Sessioni totali',
        icon: Icons.history,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _StatCard(value: stat.value, label: stat.label, icon: stat.icon);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.salvia, size: 22),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<WeeklySessionCount> weeklyTrend;

  const _WeeklyTrendChart({required this.weeklyTrend});

  static const _weekdayLabels = [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final maxCount = weeklyTrend
        .map((w) => w.count)
        .fold<int>(0, (a, b) => b > a ? b : a);
    final maxY = maxCount == 0 ? 1.0 : (maxCount + 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sessioni nelle ultime 8 settimane',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= weeklyTrend.length) {
                        return const SizedBox();
                      }
                      final weekStart = weeklyTrend[index].weekStart;
                      final label = _weekdayLabels[weekStart.weekday - 1];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$label ${weekStart.day}/${weekStart.month}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < weeklyTrend.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyTrend[i].count.toDouble(),
                        color: weeklyTrend[i].count == 0
                            ? Colors.grey.shade300
                            : AppColors.salvia,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentlyImprovedSection extends StatelessWidget {
  final List<FoodProgressSummary> items;

  const _RecentlyImprovedSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progressi recenti 🌟',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _ImprovedFoodTile(item: item)),
      ],
    );
  }
}

class _ImprovedFoodTile extends StatelessWidget {
  final FoodProgressSummary item;

  const _ImprovedFoodTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final previous = ExposureLevel.values[item.previousLevel];
    final current = ExposureLevel.values[item.currentLevel];
    final dateLabel = item.lastSessionDate != null
        ? _formatDate(item.lastSessionDate!)
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(
          item.category.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          item.foodName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${previous.label} → ${current.label}\nMigliorato il $dateLabel',
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _StagnantSection extends StatelessWidget {
  final List<FoodProgressSummary> items;
  final VoidCallback? onPlanSession;

  const _StagnantSection({required this.items, required this.onPlanSession});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Da non dimenticare',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => _StagnantFoodTile(item: item, onPlanSession: onPlanSession),
        ),
      ],
    );
  }
}

class _StagnantFoodTile extends StatelessWidget {
  final FoodProgressSummary item;
  final VoidCallback? onPlanSession;

  const _StagnantFoodTile({required this.item, required this.onPlanSession});

  @override
  Widget build(BuildContext context) {
    final daysAgo = item.lastSessionDate == null
        ? null
        : DateTime.now().difference(item.lastSessionDate!).inDays;
    final subtitle = daysAgo == null
        ? 'Nessuna sessione ancora'
        : 'Ultima sessione: $daysAgo giorni fa';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(item.category.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onPlanSession != null)
              TextButton(
                onPressed: onPlanSession,
                child: const Text('Pianifica sessione →'),
              ),
          ],
        ),
      ),
    );
  }
}

class _MotivationalMessage extends StatelessWidget {
  final int sessionsThisWeek;
  final int weeklyGoal;

  const _MotivationalMessage({
    required this.sessionsThisWeek,
    required this.weeklyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    if (sessionsThisWeek == 0) {
      message =
          'Inizia questa settimana — anche una sola sessione fa la differenza 💪';
    } else if (sessionsThisWeek > weeklyGoal) {
      message = 'Settimana eccellente — hai superato il tuo obiettivo!';
    } else if (sessionsThisWeek == weeklyGoal) {
      message = 'Obiettivo della settimana raggiunto! 🎉';
    } else {
      message = 'Stai andando bene — continua così!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pesca.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
