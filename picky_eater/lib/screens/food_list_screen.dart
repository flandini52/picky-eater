import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'add_food_screen.dart';
import 'edit_food_screen.dart';
import 'food_detail_screen.dart';

class FoodListScreen extends StatefulWidget {
  final Person person;

  const FoodListScreen({super.key, required this.person});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  List<Food> _foods = [];
  Map<String, Session?> _lastSessionByFood = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void didUpdateWidget(FoodListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id) {
      _loadFoods();
    }
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    final foods = await database.getFoodsByPerson(widget.person.id);
    // Ordine alfabetico
    foods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Map<String, Session?> lastSessions = {};
    for (final food in foods) {
      final completed = await database.getCompletedSessionsForFood(food.id);
      lastSessions[food.id] = completed.isNotEmpty ? completed.last : null;
    }

    if (!mounted) return;
    setState(() {
      _foods = foods;
      _lastSessionByFood = lastSessions;
      _loading = false;
    });
  }

  void _showLevelPicker(Food food) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                food.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...ExposureLevel.values.map((level) {
              final isSelected = food.currentLevel == level.index;
              return ListTile(
                title: Text(level.label),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.orange)
                    : null,
                onTap: () async {
                  await database.updateFoodLevel(food.id, level.index);
                  await _loadFoods();
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Alimenti di ${widget.person.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _foods.isEmpty
              ? const Center(
                  child: Text('Nessun alimento ancora. Aggiungine uno!'))
              : RefreshIndicator(
                  onRefresh: _loadFoods,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _foods.length,
                    itemBuilder: (context, index) {
                      final food = _foods[index];
                      final level = ExposureLevel.values[food.currentLevel];
                      final color = _levelColor(food.currentLevel);
                      final lastSession = _lastSessionByFood[food.id];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FoodDetailScreen(food: food),
                              ),
                            );
                            await _loadFoods();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Text(food.category.emoji,
                                    style: const TextStyle(fontSize: 26)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              level.label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (lastSession?.achievedActivity !=
                                          null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          lastSession!.achievedActivity!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.grey, size: 20),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final result =
                                          await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditFoodScreen(food: food),
                                        ),
                                      );
                                      if (result == true) await _loadFoods();
                                    } else if (value == 'level') {
                                      _showLevelPicker(food);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'level',
                                      child: Row(
                                        children: [
                                          Icon(Icons.tune, size: 18),
                                          SizedBox(width: 8),
                                          Text('Imposta livello'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Modifica'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<FoodsCompanion>(
            context,
            MaterialPageRoute(
              builder: (_) => AddFoodScreen(personId: widget.person.id),
            ),
          );
          if (result != null) {
            await database.insertFood(result);
            await _loadFoods();
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}