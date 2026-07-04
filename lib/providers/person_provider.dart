import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person_entity.dart';
import '../models/family_entity.dart';
import '../repositories/person_repository.dart';
import '../repositories/family_repository.dart';
import 'database_provider.dart';

// --- Repository providers ---

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(ref.watch(databaseProvider));
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository(ref.watch(databaseProvider));
});

// --- State ---

class FamilyState {
  final FamilyEntity? family;
  final List<PersonEntity> persons;
  final PersonEntity? selectedPerson;

  const FamilyState({
    this.family,
    this.persons = const [],
    this.selectedPerson,
  });

  FamilyState copyWith({
    FamilyEntity? family,
    List<PersonEntity>? persons,
    PersonEntity? selectedPerson,
    bool clearSelectedPerson = false,
  }) {
    return FamilyState(
      family: family ?? this.family,
      persons: persons ?? this.persons,
      selectedPerson: clearSelectedPerson
          ? null
          : selectedPerson ?? this.selectedPerson,
    );
  }
}

class FamilyNotifier extends AsyncNotifier<FamilyState> {
  @override
  Future<FamilyState> build() async {
    return _load();
  }

  Future<FamilyState> _load() async {
    final familyRepo = ref.read(familyRepositoryProvider);
    final personRepo = ref.read(personRepositoryProvider);

    var families = await familyRepo.getAllFamilies();
    if (families.isEmpty) {
      await familyRepo.insertFamily(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'La mia famiglia',
      );
      families = await familyRepo.getAllFamilies();
    }
    final family = families.first;
    final persons = await personRepo.getPersonsByFamily(family.id);

    final currentSelected = state.valueOrNull?.selectedPerson;
    final selectedPerson = persons.isNotEmpty
        ? (currentSelected != null &&
                  persons.any((p) => p.id == currentSelected.id)
              ? persons.firstWhere((p) => p.id == currentSelected.id)
              : persons.first)
        : null;

    return FamilyState(
      family: family,
      persons: persons,
      selectedPerson: selectedPerson,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> addPerson(String name) async {
    final familyId = state.valueOrNull?.family?.id;
    if (familyId == null) return;
    final personRepo = ref.read(personRepositoryProvider);
    await personRepo.insertPerson(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      familyId: familyId,
      name: name,
    );
    await refresh();
    final persons = state.valueOrNull?.persons ?? [];
    if (persons.isNotEmpty) {
      selectPerson(persons.last);
    }
  }

  void selectPerson(PersonEntity person) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedPerson: person));
  }
}

final familyProvider = AsyncNotifierProvider<FamilyNotifier, FamilyState>(
  FamilyNotifier.new,
);
