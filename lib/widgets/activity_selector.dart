import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Lista di attività selezionabili, riutilizzabile sia nella pianificazione
/// che nella registrazione sessione.
class ActivitySelector extends StatelessWidget {
  final List<String> activities;
  final String? selected;
  final ValueChanged<String> onSelected;

  const ActivitySelector({
    super.key,
    required this.activities,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: activities.map((activity) {
        final isSelected = selected == activity;
        return GestureDetector(
          onTap: () => onSelected(activity),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.salvia.withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.salvia : Colors.grey.shade300,
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
                Expanded(child: Text(activity)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
