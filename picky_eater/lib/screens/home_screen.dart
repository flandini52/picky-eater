import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'food_list_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'edit_person_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _dataVersion = 0;
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
        _selectedPerson = persons.isNotEmpty
            ? (_selectedPerson != null &&
                    persons.any((p) => p.id == _selectedPerson!.id)
                ? persons.firstWhere((p) => p.id == _selectedPerson!.id)
                : persons.first)
            : null;
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
                final persons =
                    await database.getPersonsByFamily(_family!.id);
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

  Future<void> _editPerson(Person person) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPersonScreen(person: person)),
    );
    if (result == true) await _initData();
  }

  void _refreshData() {
    setState(() => _dataVersion++);
  }

  void _openPersonMenu() {
    showMenu<void>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 90, 200, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        ..._persons.map(
          (p) => PopupMenuItem<void>(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: _selectedPerson?.id == p.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onPressed: () {
                    Navigator.pop(context);
                    _editPerson(p);
                  },
                ),
              ],
            ),
            onTap: () => setState(() => _selectedPerson = p),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => Future.delayed(Duration.zero, _addPerson),
          child: const Row(
            children: [
              Icon(Icons.add, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('Aggiungi persona o membro',
                  style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      ],
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SettingsSheet(),
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
                top: 30, left: 12, right: 4, bottom: 6),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _family == null
                      ? null
                      : (_persons.isEmpty ? _addPerson : _openPersonMenu),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedPerson?.name ?? 'Aggiungi persona',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings,
                      color: Colors.white, size: 20),
                  onPressed: _openSettings,
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
                    ? DashboardScreen(key: ValueKey('dashboard_$_dataVersion'), person: _selectedPerson!)
                    : _currentIndex == 1
                        ? FoodListScreen(key: ValueKey('foodlist_$_dataVersion'), person: _selectedPerson!)
                        : CalendarScreen(key: ValueKey('calendar_$_dataVersion'), person: _selectedPerson!, onDataChanged: _refreshData),
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

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Impostazioni',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.language, color: Colors.grey),
            title: Text('Lingua'),
            trailing: Text('Italiano', style: TextStyle(color: Colors.grey)),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined, color: Colors.grey),
            title: Text('Notifiche'),
            trailing: Text('Presto disponibile',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            enabled: false,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}