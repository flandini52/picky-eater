import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../models/person_entity.dart';
import '../providers/person_provider.dart';
import '../providers/dashboard_provider.dart';
import 'food_list_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'edit_person_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _dataVersion = 0;

  void _refreshData() {
    setState(() => _dataVersion++);
    // Invalida anche la dashboard Riverpod
    final personId = ref.read(familyProvider).valueOrNull?.selectedPerson?.id;
    if (personId != null) {
      ref.invalidate(dashboardProvider(personId));
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
                await ref
                    .read(familyProvider.notifier)
                    .addPerson(nameController.text);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Errore: $e')));
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

  Future<void> _editPerson(PersonEntity person) async {
    // Convertiamo PersonEntity in Person per la schermata di modifica
    // che per ora usa ancora i tipi Drift — lo migreremo nel passo successivo
    final driftPerson = Person(
      id: person.id,
      familyId: person.familyId,
      name: person.name,
      birthDate: person.birthDate,
      avatarColor: person.avatarColor,
    );
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPersonScreen(person: driftPerson)),
    );
    if (result == true) {
      await ref.read(familyProvider.notifier).refresh();
    }
  }

  void _openPersonMenu(List<PersonEntity> persons, PersonEntity? selected) {
    showMenu<void>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 90, 200, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        ...persons.map(
          (p) => PopupMenuItem<void>(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: selected?.id == p.id
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
            onTap: () => ref.read(familyProvider.notifier).selectPerson(p),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => Future.delayed(Duration.zero, _addPerson),
          child: const Row(
            children: [
              Icon(Icons.add, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Aggiungi persona o membro',
                style: TextStyle(color: Colors.orange),
              ),
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
    final familyAsync = ref.watch(familyProvider);

    return familyAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Errore: $e'))),
      data: (familyState) {
        final persons = familyState.persons;
        final selectedPerson = familyState.selectedPerson;

        return Scaffold(
          body: Column(
            children: [
              Container(
                color: Colors.orange,
                padding: const EdgeInsets.only(
                  top: 30,
                  left: 12,
                  right: 4,
                  bottom: 6,
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: familyState.family == null
                          ? null
                          : (persons.isEmpty
                                ? _addPerson
                                : () =>
                                      _openPersonMenu(persons, selectedPerson)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedPerson?.name ?? 'Aggiungi persona',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedPerson == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Nessuna persona ancora.'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: familyState.family == null
                                  ? null
                                  : _addPerson,
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
                    ? DashboardScreen(
                        key: ValueKey('dashboard_${selectedPerson.id}'),
                        person: Person(
                          id: selectedPerson.id,
                          familyId: selectedPerson.familyId,
                          name: selectedPerson.name,
                          birthDate: selectedPerson.birthDate,
                          avatarColor: selectedPerson.avatarColor,
                        ),
                      )
                    : _currentIndex == 1
                    ? FoodListScreen(
                        key: ValueKey(
                          'foodlist_${selectedPerson.id}_$_dataVersion',
                        ),
                        person: Person(
                          id: selectedPerson.id,
                          familyId: selectedPerson.familyId,
                          name: selectedPerson.name,
                          birthDate: selectedPerson.birthDate,
                          avatarColor: selectedPerson.avatarColor,
                        ),
                      )
                    : CalendarScreen(
                        person: Person(
                          id: selectedPerson.id,
                          familyId: selectedPerson.familyId,
                          name: selectedPerson.name,
                          birthDate: selectedPerson.birthDate,
                          avatarColor: selectedPerson.avatarColor,
                        ),
                        onDataChanged: _refreshData,
                      ),
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
      },
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
            trailing: Text(
              'Presto disponibile',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            enabled: false,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
