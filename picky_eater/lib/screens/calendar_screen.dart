import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/app_database.dart';
import '../main.dart';

class CalendarScreen extends StatefulWidget {
  final Person person;

  const CalendarScreen({super.key, required this.person});

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
        onSave: () => _loadSessionsForDay(day),
      ),
    );
  }

  void _completeSession(Session session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CompleteSessionSheet(
        session: session,
        onSave: (achievedLevel, notes) async {
          await database.completeSession(
              session.id, achievedLevel, notes);
          if (_selectedDay != null) _loadSessionsForDay(_selectedDay!);
        },
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
                        final targetLevel =
                            ExposureLevel.values[session.targetLevel];
                        final achieved = session.achievedLevel != null
                            ? ExposureLevel
                                .values[session.achievedLevel!]
                            : null;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(session.foodId),
                            subtitle:
                                Text('Obiettivo: ${targetLevel.label}'),
                            trailing: achieved != null
                                ? Text(achieved.label)
                                : ElevatedButton(
                                    onPressed: () =>
                                        _completeSession(session),
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
  ExposureLevel selectedTarget = ExposureLevel.totalRefusal;

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
          const Text('Nuova sessione',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Food>(
            hint: const Text('Scegli alimento'),
            value: selectedFood,
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
            value: selectedTarget,
            items: ExposureLevel.values
                .map((l) =>
                    DropdownMenuItem(value: l, child: Text(l.label)))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedTarget = value!),
            decoration: const InputDecoration(
              labelText: 'Livello obiettivo',
              border: OutlineInputBorder(),
            ),
          ),
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
    );
  }
}

class _CompleteSessionSheet extends StatefulWidget {
  final Session session;
  final Function(int, String?) onSave;

  const _CompleteSessionSheet({
    required this.session,
    required this.onSave,
  });

  @override
  State<_CompleteSessionSheet> createState() =>
      _CompleteSessionSheetState();
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
          const Text('Come è andata?',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExposureLevel>(
            value: selectedLevel,
            items: ExposureLevel.values
                .map((l) =>
                    DropdownMenuItem(value: l, child: Text(l.label)))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedLevel = value!),
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