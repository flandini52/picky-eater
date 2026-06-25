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
    final foods = await database.getFoodsByPerson(widget.person.id);
    final List<_FoodProgress> progress = [];
    for (final food in foods) {
      final count = await database.getSessionCountForFood(food.id);
      progress.add(_FoodProgress(food: food, sessionCount: count));
    }
    setState(() {
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
          : _progress.isEmpty
              ? const Center(
                  child: Text('Nessun alimento ancora.\nVai su Alimenti per aggiungerne uno!',
                      textAlign: TextAlign.center),
                )
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  color: Colors.orange,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
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
                              // Emoji categoria
                              Text(
                                food.category.emoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                              // Nome alimento
                              Text(
                                food.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Barra progresso
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (food.currentLevel + 1) / 5,
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
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              // Numero sessioni
                              Row(
                                children: [
                                  Icon(Icons.event_note,
                                      size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.sessionCount} sessioni',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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