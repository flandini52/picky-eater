import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/app_database.dart';
import '../main.dart';

class CalendarScreen extends StatefulWidget {
  final Person person;
  final VoidCallback onDataChanged;

  const CalendarScreen({
    super.key,
    required this.person,
    required this.onDataChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Session> _sessionsForDay = [];
  List<Food> _foods = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id) {
      _loadFoods();
      if (_selectedDay != null) _loadSessionsForDay(_selectedDay!);
    }
  }

  Future<void> _loadFoods() async {
    final foods = await database.getFoodsByPerson(widget.person.id);
    setState(() => _foods = foods);
  }

  Future<void> _loadSessionsForDay(DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    final sessions = await database.getSessionsByPersonAndDate(
        widget.person.id, normalized);
    setState(() => _sessionsForDay = sessions);
  }

  Future<List<Session>> _getSessionsForDay(DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    return database.getSessionsByPersonAndDate(widget.person.id, normalized);
  }

  void _addSession(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSessionSheet(
        date: day,
        foods: _foods,
        personId: widget.person.id,
        onSave: () {
          _loadSessionsForDay(day);
          widget.onDataChanged();
        },
      ),
    );
  }

  void _completeSession(Session session) {
    final food = _foods.firstWhere((f) => f.id == session.foodId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CompleteSessionSheet(
        session: session,
        food: food,
        onSave: (achievedLevel, notes) async {
          await database.completeSession(session.id, achievedLevel, notes);
          final newBadges = await database.checkAndUnlockBadges(
              widget.person.id, food.id, achievedLevel);
          if (_selectedDay != null) _loadSessionsForDay(_selectedDay!);
          widget.onDataChanged();
          if (newBadges.isNotEmpty && mounted) {
            for (final badge in newBadges) {
              _showBadgeUnlockedDialog(badge);
            }
          }
        },
      ),
    );
  }

  void _showBadgeUnlockedDialog(BadgeType badge) {
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Fantastico!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadSessionsForDay(selectedDay);
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          if (_selectedDay != null) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _addSession(_selectedDay!),
                    icon: const Icon(Icons.add, color: Colors.orange),
                    label: const Text('Aggiungi',
                        style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _sessionsForDay.isEmpty
                  ? const Center(
                      child: Text('Nessuna sessione per questo giorno'))
                  : ListView.builder(
                      itemCount: _sessionsForDay.length,
                      itemBuilder: (context, index) {
                        final session = _sessionsForDay[index];
                        final targetLevel = ExposureLevel.values[session.targetLevel];
                        final achieved = session.achievedLevel != null
                            ? ExposureLevel.values[session.achievedLevel!]
                            : null;
                        
                        // Trova il nome del cibo dalla lista già caricata
                        final food = _foods.firstWhere(
                          (f) => f.id == session.foodId,
                          orElse: () => _foods.first,
                        );
                        
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: session.activity != null,
                            trailing: achieved != null
                                ? Text(achieved.label)
                                : ElevatedButton(
                                    onPressed: () => _completeSession(session),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Registra'),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ] else
            const Expanded(
              child: Center(
                child:
                    Text('Seleziona un giorno per vedere le sessioni'),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddSessionSheet extends StatefulWidget {
  final DateTime date;
  final List<Food> foods;
  final String personId;
  final VoidCallback onSave;

  const _AddSessionSheet({
    required this.date,
    required this.foods,
    required this.personId,
    required this.onSave,
  });

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  Food? selectedFood;
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<Food>(
              hint: const Text('Scegli alimento'),
              value: selectedFood,
              items: widget.foods
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                  .toList(),
              onChanged: (value) => setState(() => selectedFood = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExposureLevel>(
              value: selectedTarget,
              items: ExposureLevel.values
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedTarget = value!;
                selectedActivity = null; // reset attività quando cambia livello
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
            ...activities.map((activity) {
              final isSelected = selectedActivity == activity;
              return GestureDetector(
                onTap: () => setState(() => selectedActivity = activity),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(activity)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedFood == null
                    ? null
                    : () async {
                        await database.insertSession(
                          SessionsCompanion.insert(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            personId: widget.personId,
                            foodId: selectedFood!.id,
                            date: widget.date,
                            targetLevel: selectedTarget.index,
                            activity: Value(selectedActivity),
                          ),
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

class _CompleteSessionSheet extends StatefulWidget {
  final Session session;
  final Food food;
  final Function(int, String?) onSave;

  const _CompleteSessionSheet({
    required this.session,
    required this.food,
    required this.onSave,
  });

  @override
  State<_CompleteSessionSheet> createState() => _CompleteSessionSheetState();
}

class _CompleteSessionSheetState extends State<_CompleteSessionSheet> {
  late ExposureLevel selectedLevel;
  final TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLevel = ExposureLevel.values[widget.session.targetLevel];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Completa sessione',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cibo: ${widget.food.name}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExposureLevel>(
            value: selectedLevel,
            items: ExposureLevel.values
                .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                .toList(),
            onChanged: (value) => setState(() => selectedLevel = value!),
            decoration: const InputDecoration(
              labelText: 'Livello raggiunto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Note (opzionale)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  selectedLevel.index,
                  notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Salva'),
            ),
          ),
        ],
      ),
    );
  }
}