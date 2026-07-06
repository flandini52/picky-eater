import 'package:flutter/material.dart';
import '../core/exposure_level.dart';
import '../models/food_entity.dart';

class AddFoodScreen extends StatefulWidget {
  final String personId;

  const AddFoodScreen({super.key, required this.personId});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController nameController = TextEditingController();
  String selectedCategory = 'frutta';
  ExposureLevel selectedLevel = ExposureLevel.tolerates;
  bool isSafeFood = false;

  final List<String> categories = [
    'frutta',
    'verdura',
    'carne',
    'pesce',
    'carboidrati',
    'latticini',
    'dolci',
  ];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo alimento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome alimento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Categoria'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('È un safe food?'),
              subtitle: const Text(
                'Un alimento che il bambino già mangia senza difficoltà',
              ),
              value: isSafeFood,
              onChanged: (value) => setState(() => isSafeFood = value),
            ),
            if (!isSafeFood) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<ExposureLevel>(
                initialValue: selectedLevel,
                items: ExposureLevel.values
                    .map(
                      (l) => DropdownMenuItem(value: l, child: Text(l.label)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedLevel = value!),
                decoration: const InputDecoration(
                  labelText: 'Livello iniziale',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  // Restituisce FoodEntity invece di FoodsCompanion
                  final entity = FoodEntity(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    personId: widget.personId,
                    name: nameController.text,
                    category: selectedCategory,
                    currentLevel: isSafeFood
                        ? ExposureLevel.eats.index
                        : selectedLevel.index,
                    isSafeFood: isSafeFood,
                  );
                  Navigator.pop(context, entity);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Aggiungi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
