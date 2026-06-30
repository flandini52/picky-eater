import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final Person person;

  const DashboardScreen({super.key, required this.person});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<_FoodProgress> _progress = [];
  bool _loading = true;
  int _weeklyGoal = 3;
  int _sessionsThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    setState(() => _loading = true);
    final goal = await database.getWeeklyGoal(widget.person.id);
    final thisWeek = await database.getSessionsThisWeek(widget.person.id);
    final foods = await database.getFoodsByPerson(widget.person.id);
    final List<_FoodProgress> progress = [];
    for (final food in foods) {
      final count = await database.getSessionCountForFood(food.id);
      progress.add(_FoodProgress(food: food, sessionCount: count));
    }
    setState(() {
      _weeklyGoal = goal;
      _sessionsThisWeek = thisWeek;
      _progress = progress;
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
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progressi di ${widget.person.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadProgress,
              color: Colors.orange,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Card obiettivo settimanale
                  Container(
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_sessionsThisWeek / _weeklyGoal).clamp(0, 1),
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_sessionsThisWeek di $_weeklyGoal sessioni questa settimana',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_progress.isEmpty)
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
                      itemCount: _progress.length,
                      itemBuilder: (context, index) {
                        final item = _progress[index];
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(color),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      level.label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.event_note,
                                        size: 14,
                                        color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.sessionCount} sessioni',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _FoodProgress {
  final Food food;
  final int sessionCount;

  _FoodProgress({required this.food, required this.sessionCount});
}