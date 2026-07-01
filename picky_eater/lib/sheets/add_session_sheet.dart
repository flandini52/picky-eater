import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../models/food_entity.dart';
import '../providers/calendar_provider.dart';
import '../widgets/activity_selector.dart';

class AddSessionSheet extends ConsumerStatefulWidget {
  final String personId;
  final DateTime date;
  final List<FoodEntity> foods;
  final VoidCallback onSave;

  const AddSessionSheet({
    super.key,
    required this.personId,
    required this.date,
    required this.foods,
    required this.onSave,
  });

  @override
  ConsumerState<AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends ConsumerState<AddSessionSheet> {
  FoodEntity? selectedFood;
  ExposureLevel selectedTarget = ExposureLevel.tolerates;
  String? selectedActivity;

  @override
  Widget build(BuildContext context) {
    final activities = levelActivities[selectedTarget] ?? [];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuova sessione',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<FoodEntity>(
              hint: const Text('Scegli alimento'),
              initialValue: selectedFood,
              items: widget.foods
                  .map((f) =>
                      DropdownMenuItem(value: f, child: Text(f.name)))
                  .toList(),
              onChanged: (value) => setState(() => selectedFood = value),
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExposureLevel>(
              initialValue: selectedTarget,
              items: ExposureLevel.values
                  .map((l) =>
                      DropdownMenuItem(value: l, child: Text(l.label)))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedTarget = value!;
                selectedActivity = null;
              }),
              decoration: const InputDecoration(
                labelText: 'Livello obiettivo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Attività suggerita',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ActivitySelector(
              activities: activities,
              selected: selectedActivity,
              onSelected: (a) => setState(() => selectedActivity = a),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedFood == null
                    ? null
                    : () async {
                        await ref
                            .read(calendarProvider(widget.personId)
                                .notifier)
                            .addSession(
                              personId: widget.personId,
                              foodId: selectedFood!.id,
                              date: widget.date,
                              targetLevel: selectedTarget.index,
                              activity: selectedActivity,
                            );
                        widget.onSave();
                        if (context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Pianifica sessione'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}