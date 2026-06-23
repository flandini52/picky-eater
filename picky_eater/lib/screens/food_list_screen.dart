import 'package:flutter/material.dart';
import '../models/alimento.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  // Lista di alimenti di esempio per ora
  final List<Food> foods = [
    Food(id: '1', name: 'Carota', category: 'verdura'),
    Food(id: '2', name: 'Mela', category: 'frutta'),
    Food(id: '3', name: 'Pollo', category: 'carne'),
    Food(id: '4', name: 'Pasta', category: 'carboidrati'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimenti'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(food.name),
              subtitle: Text(food.category),
              trailing: Text(food.level.label),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // qui aggiungeremo il form per un nuovo alimento
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}