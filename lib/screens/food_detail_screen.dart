import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_theme.dart';
import '../core/exposure_level.dart';
import '../database/app_database.dart';
import '../models/food_entity.dart';
import '../models/session_entity.dart';
import '../providers/dashboard_provider.dart';

class FoodDetailScreen extends ConsumerWidget {
  final FoodEntity food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
      body: FutureBuilder<List<SessionEntity>>(
        future: sessionRepo.getCompletedSessionsForFood(food.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          final level = ExposureLevel.values[food.currentLevel];

          return RefreshIndicator(
            onRefresh: () async {
              (context as Element).markNeedsBuild();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text(
                      food.category.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            level.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'Nessuna sessione registrata ancora.\nPianificane una dal calendario!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else ...[
                  _StatsRow(sessions: sessions),
                  const SizedBox(height: 24),
                  const Text(
                    'Andamento nel tempo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: _ProgressChart(sessions: sessions),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Storico sessioni',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...sessions.reversed.map((s) => _HistoryItem(session: s)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<SessionEntity> sessions;

  const _StatsRow({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final firstDate = sessions.first.date;
    final lastDate = sessions.last.date;
    final daysSinceLast = DateTime.now().difference(lastDate).inDays;

    return Row(
      children: [
        Expanded(child: _StatCard('${sessions.length}', 'Sessioni totali')),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            '${firstDate.day}/${firstDate.month}',
            'Prima sessione',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            daysSinceLast == 0 ? 'Oggi' : '$daysSinceLast gg fa',
            'Ultima sessione',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.salvia.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.salvia,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final List<SessionEntity> sessions;

  const _ProgressChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final firstDate = sessions.first.date;
    final spots = <FlSpot>[];

    for (final session in sessions) {
      final daysSinceStart = session.date
          .difference(firstDate)
          .inDays
          .toDouble();
      int granular = granularIndexForActivity(session.achievedActivity);
      if (granular == -1) {
        granular = session.achievedLevel! * 3 + 1;
      }
      spots.add(FlSpot(daysSinceStart, granular.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 17,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 3,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                final levelIndex = (value / 3).floor();
                if (levelIndex < 0 ||
                    levelIndex >= ExposureLevel.values.length) {
                  return const SizedBox();
                }
                if (value % 3 != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    ExposureLevel.values[levelIndex].label,
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final date = firstDate.add(Duration(days: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.salvia,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.salvia,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.salvia.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SessionEntity session;

  const _HistoryItem({required this.session});

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
    final achievedLevel = ExposureLevel.values[session.achievedLevel!];
    final targetLevel = ExposureLevel.values[session.targetLevel];
    final color = _levelColor(session.achievedLevel!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '${session.date.day}/${session.date.month}/${session.date.year}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(achievedLevel.label, style: const TextStyle(fontSize: 11)),
            ],
          ),
          if (session.achievedActivity != null) ...[
            const SizedBox(height: 6),
            Text(
              session.achievedActivity!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
          if (session.achievedLevel != session.targetLevel) ...[
            const SizedBox(height: 4),
            Text(
              'Obiettivo era: ${targetLevel.label}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              session.notes!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
