import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../core/badge_type.dart';
import '../core/exposure_level.dart';
import '../models/food_entity.dart';
import '../models/session_entity.dart';
import '../providers/calendar_provider.dart';
import '../widgets/activity_selector.dart';
import '../widgets/outcome_badge.dart';

class CompleteSessionSheet extends ConsumerStatefulWidget {
  final String personId;
  final String personName;
  final SessionEntity session;
  final FoodEntity food;
  final Future<void> Function(List<BadgeType>) onCompleted;

  const CompleteSessionSheet({
    super.key,
    required this.personId,
    required this.personName,
    required this.session,
    required this.food,
    required this.onCompleted,
  });

  @override
  ConsumerState<CompleteSessionSheet> createState() =>
      _CompleteSessionSheetState();
}

class _CompleteSessionSheetState extends ConsumerState<CompleteSessionSheet> {
  late ExposureLevel selectedLevel;
  String? selectedActivity;
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLevel = ExposureLevel.values[widget.session.targetLevel];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetLevel = ExposureLevel.values[widget.session.targetLevel];
    final activitiesForLevel = levelActivities[selectedLevel] ?? [];

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
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Registra sessione',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.food.name} · Obiettivo: ${targetLevel.label}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            OutcomeBadge(
              targetLevel: widget.session.targetLevel,
              achievedLevel: selectedLevel.index,
            ),
            const SizedBox(height: 20),
            const Text(
              'Qual è il livello più alto raggiunto oggi?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ExposureLevel.values.map((level) {
              final isSelected = selectedLevel == level;
              return GestureDetector(
                onTap: () => setState(() {
                  selectedLevel = level;
                  selectedActivity = null;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.salvia.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.salvia
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.salvia : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              level.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Quale attività ha completato?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ActivitySelector(
              activities: activitiesForLevel,
              selected: selectedActivity,
              onSelected: (a) => setState(() => selectedActivity = a),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Note (opzionale)',
                border: OutlineInputBorder(),
                hintText: 'Come si è comportato? Reazioni particolari?',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final badges = await ref
                      .read(calendarProvider(widget.personId).notifier)
                      .completeSession(
                        personId: widget.personId,
                        personName: widget.personName,
                        sessionId: widget.session.id,
                        foodId: widget.food.id,
                        currentFoodLevel: widget.food.currentLevel,
                        achievedLevel: selectedLevel.index,
                        achievedActivity: selectedActivity,
                        notes: notesController.text.isEmpty
                            ? null
                            : notesController.text,
                      );
                  await widget.onCompleted(badges);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Salva sessione'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
