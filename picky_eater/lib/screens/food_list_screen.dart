import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'add_food_screen.dart';
import 'edit_food_screen.dart';


class FoodListScreen extends StatefulWidget {
  final Person person;

  const FoodListScreen({super.key, required this.person});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  List<Food> _foods = [];

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
    final foods = await database.getFoodsByPerson(widget.person.id);
    setState(() => _foods = foods);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alimenti di ${widget.person.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _foods.isEmpty
          ? const Center(child: Text('Nessun alimento ancora. Aggiungine uno!'))
          : ListView.builder(
              itemCount: _foods.length,
              itemBuilder: (context, index) {
                final food = _foods[index];
                final level = ExposureLevel.values[food.currentLevel];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(food.name),
                    subtitle: Text(food.category),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(level.label),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditFoodScreen(food: food)),
                                );
                                if (result == true) await _loadFoods();
                              }
                            },
                            itemBuilder: (context) => [
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
                    onTap: () => _showLevelPicker(food),
                  ),
                );
              },
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