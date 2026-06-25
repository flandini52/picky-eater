import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'food_list_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Person? _selectedPerson;
  List<Person> _persons = [];
  Family? _family;

  @override
  void initState() {
    super.initState();
    _initData();
  }

Future<void> _initData() async {
  try {
    final families = await database.getAllFamilies();
    if (families.isEmpty) {
      await database.insertFamily(
        FamiliesCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'La mia famiglia',
        ),
      );
    }
    final family = (await database.getAllFamilies()).first;
    final persons = await database.getPersonsByFamily(family.id);
    setState(() {
      _family = family;
      _persons = persons;
      _selectedPerson = persons.isNotEmpty ? persons.first : null;
    });
  } catch (e) {
    debugPrint('Errore initData: $e');
  }
}

Future<void> _addPerson() async {
  final nameController = TextEditingController();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Aggiungi persona'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: 'Nome',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isEmpty) return;
            try {
              await database.insertPerson(
                PersonsCompanion.insert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  familyId: _family!.id,
                  name: nameController.text,
                ),
              );
              final persons = await database.getPersonsByFamily(_family!.id);
              setState(() {
                _persons = persons;
                _selectedPerson = persons.last;
              });
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              debugPrint('Errore addPerson: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aggiungi'),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.orange,
            padding: const EdgeInsets.only(
                top: 48, left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                const Text(
                  'Picky Eater',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_persons.isNotEmpty)
                  DropdownButton<Person>(
                    value: _selectedPerson,
                    dropdownColor: Colors.orange,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    underline: const SizedBox(),
                    items: _persons
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name,
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (p) => setState(() => _selectedPerson = p),
                  ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: _family == null ? null : _addPerson,
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedPerson == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Nessuna persona ancora.'),
                        const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _family == null ? null : _addPerson,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Aggiungi persona'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ],
                    ),
                  )
                : _currentIndex == 0
                    ? DashboardScreen(person: _selectedPerson!)
                    : _currentIndex == 1
                        ? FoodListScreen(person: _selectedPerson!)
                        : CalendarScreen(person: _selectedPerson!),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Progressi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Alimenti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}