import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/app_database.dart';
import '../main.dart';

class FoodDetailScreen extends StatefulWidget {
  final Food food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  List<Session> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    final sessions = await database.getCompletedSessionsForFood(widget.food.id);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

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
    final level = ExposureLevel.values[widget.food.currentLevel];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.food.name),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: Colors.orange,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header riassuntivo
                  Row(
                    children: [
                      Text(widget.food.category.emoji,
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.label,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              level.description,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_sessions.isEmpty)
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
                    // Statistiche rapide
                    _buildStatsRow(),
                    const SizedBox(height: 24),

                    // Grafico andamento
                    const Text(
                      'Andamento nel tempo',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: _buildChart(),
                    ),
                    const SizedBox(height: 28),

                    // Storico sessioni
                    const Text(
                      'Storico sessioni',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._sessions.reversed.map((session) => _buildHistoryItem(session)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final firstDate = _sessions.first.date;
    final lastDate = _sessions.last.date;
    final daysSinceLast = DateTime.now().difference(lastDate).inDays;

    return Row(
      children: [
        Expanded(
          child: _statCard('${_sessions.length}', 'Sessioni totali'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
              '${firstDate.day}/${firstDate.month}', 'Prima sessione'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            daysSinceLast == 0 ? 'Oggi' : '$daysSinceLast gg fa',
            'Ultima sessione',
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange)),
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

  Widget _buildChart() {
    // Costruiamo i punti: x = giorni dalla prima sessione, y = indice granulare 0-17
    final firstDate = _sessions.first.date;
    final spots = <FlSpot>[];

    for (final session in _sessions) {
      final daysSinceStart =
          session.date.difference(firstDate).inDays.toDouble();
      int granular = granularIndexForActivity(session.achievedActivity);
      if (granular == -1) {
        // Fallback: usa il centro del livello macro se non c'è attività specifica
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
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            color: Colors.orange,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: Colors.orange,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Session session) {
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
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                achievedLevel.label,
                style: const TextStyle(fontSize: 11),
              ),
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
                  color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}