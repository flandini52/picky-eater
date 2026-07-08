import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/app_theme.dart';
import '../core/badge_type.dart';
import '../core/exposure_level.dart';
import '../core/food_category_color.dart';
import '../database/app_database.dart';
import '../models/food_entity.dart';
import '../models/session_entity.dart';
import '../providers/calendar_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/outcome_badge.dart';
import '../sheets/add_session_sheet.dart';
import '../sheets/complete_session_sheet.dart';

class CalendarScreen extends ConsumerWidget {
  final Person person;
  final VoidCallback? onDataChanged;

  const CalendarScreen({super.key, required this.person, this.onDataChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarProvider(person.id));

    return Scaffold(
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (calState) => Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2027, 12, 31),
              focusedDay: calState.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(calState.selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                ref
                    .read(calendarProvider(person.id).notifier)
                    .selectDay(person.id, selectedDay);
              },
              onPageChanged: (focusedDay) {
                ref
                    .read(calendarProvider(person.id).notifier)
                    .loadMarkersForMonth(person.id, focusedDay);
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppColors.salvia,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.pesca,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) {
                final normalized = DateTime(day.year, day.month, day.day);
                return calState.markers[normalized] ?? [];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox();
                  final markers = events.cast<SessionMarker>();

                  // Prima i completati, poi i pianificati — max 3 (limite
                  // nativo di table_calendar).
                  final sorted = [
                    ...markers.where((m) => m.isCompleted),
                    ...markers.where((m) => !m.isCompleted),
                  ].take(3).toList();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sorted.map((marker) {
                      final color = marker.isCompleted
                          ? (marker.foodCategory?.categoryColor ??
                                AppColors.salvia)
                          : Colors.grey.shade400;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const Divider(),
            if (calState.selectedDay != null) ...[
              _DayHeader(
                day: calState.selectedDay!,
                onAdd: () => _showAddSession(
                  context,
                  ref,
                  calState.selectedDay!,
                  calState.foods,
                ),
              ),
              Expanded(
                child: calState.sessionsForDay.isEmpty
                    ? const Center(
                        child: Text('Nessuna sessione per questo giorno'),
                      )
                    : ListView.builder(
                        itemCount: calState.sessionsForDay.length,
                        itemBuilder: (context, index) {
                          final session = calState.sessionsForDay[index];
                          final food = calState.foods.firstWhere(
                            (f) => f.id == session.foodId,
                            orElse: () => calState.foods.first,
                          );
                          return _SessionCard(
                            session: session,
                            food: food,
                            onRegister: () => _showCompleteSession(
                              context,
                              ref,
                              session,
                              food,
                            ),
                          );
                        },
                      ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Seleziona un giorno per vedere le sessioni'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddSession(
    BuildContext context,
    WidgetRef ref,
    DateTime day,
    List<FoodEntity> foods,
  ) {
    // Solo gli alimenti in percorso SOS: i safe food non vanno pianificati.
    final sosFoods = foods.where((f) => !f.isSafeFood).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSessionSheet(
        personId: person.id,
        date: day,
        foods: sosFoods,
        onSave: () {
          if (onDataChanged != null) onDataChanged!();
          ref.invalidate(dashboardProvider(person.id));
        },
      ),
    );
  }

  void _showCompleteSession(
    BuildContext context,
    WidgetRef ref,
    SessionEntity session,
    FoodEntity food,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CompleteSessionSheet(
        personId: person.id,
        personName: person.name,
        session: session,
        food: food,
        onCompleted: (badges) async {
          if (onDataChanged != null) onDataChanged!();
          ref.invalidate(dashboardProvider(person.id));
          if (badges.isNotEmpty && context.mounted) {
            for (final badge in badges) {
              _showBadgeDialog(context, badge);
            }
          }
        },
      ),
    );
  }

  void _showBadgeDialog(BuildContext context, BadgeType badge) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Traguardo sbloccato!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              badge.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fantastico!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final VoidCallback onAdd;

  const _DayHeader({required this.day, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${day.day}/${day.month}/${day.year}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: AppColors.salvia),
            label: const Text(
              'Aggiungi',
              style: TextStyle(color: AppColors.salvia),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionEntity session;
  final FoodEntity food;
  final VoidCallback onRegister;

  const _SessionCard({
    required this.session,
    required this.food,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final targetLevel = ExposureLevel.values[session.targetLevel];
    final achieved = session.achievedLevel != null
        ? ExposureLevel.values[session.achievedLevel!]
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(food.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Obiettivo: ${targetLevel.label}'),
            if (session.activity != null)
              Text(
                '📋 ${session.activity}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (achieved != null && session.achievedActivity != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '✓ ${session.achievedActivity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine:
            session.activity != null || session.achievedActivity != null,
        trailing: achieved != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(achieved.label, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  OutcomeBadge(
                    targetLevel: session.targetLevel,
                    achievedLevel: session.achievedLevel!,
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: onRegister,
                child: const Text('Registra'),
              ),
      ),
    );
  }
}
