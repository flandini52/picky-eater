import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// Spostato qui da alimento.dart
enum ExposureLevel {
  tolerates,
  interacts,
  smells,
  touches,
  tastes,
  eats,
}

extension ExposureLevelExtension on ExposureLevel {
  String get label {
    switch (this) {
      case ExposureLevel.tolerates:
        return '🔴 Tollera';
      case ExposureLevel.interacts:
        return '🟠 Interagisce';
      case ExposureLevel.smells:
        return '🟡 Annusa';
      case ExposureLevel.touches:
        return '🟢 Tocca';
      case ExposureLevel.tastes:
        return '🔵 Assaggia';
      case ExposureLevel.eats:
        return '⭐ Mangia';
    }
  }

  String get description {
    switch (this) {
      case ExposureLevel.tolerates:
        return 'È nella stessa stanza con il cibo';
      case ExposureLevel.interacts:
        return 'Usa utensili o tocca il cibo con strumenti';
      case ExposureLevel.smells:
        return 'Si avvicina e annusa il cibo';
      case ExposureLevel.touches:
        return 'Tocca il cibo con dita, mano o viso';
      case ExposureLevel.tastes:
        return 'Porta il cibo alle labbra o punta della lingua';
      case ExposureLevel.eats:
        return 'Mastica e deglutisce';
    }
  }
}

extension CategoryExtension on String {
  String get emoji {
    switch (toLowerCase()) {
      case 'frutta':
        return '🍎';
      case 'verdura':
        return '🥦';
      case 'carne':
        return '🍗';
      case 'pesce':
        return '🐟';
      case 'carboidrati':
        return '🍝';
      case 'latticini':
        return '🧀';
      case 'dolci':
        return '🍬';
      default:
        return '🍽️';
    }
  }
}

// --- Tables ---

class Families extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Persons extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get name => text()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  IntColumn get avatarColor => integer().withDefault(const Constant(0xFFFF9800))();

  @override
  Set<Column> get primaryKey => {id};
}

class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(Persons, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get currentLevel => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(Persons, #id)();
  TextColumn get foodId => text().references(Foods, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get targetLevel => integer()();
  IntColumn get achievedLevel => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(tables: [Families, Persons, Foods, Sessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'picky_eater_db');
  }

  // --- Families ---
  Future<List<Family>> getAllFamilies() => select(families).get();
  
  Future<void> insertFamily(FamiliesCompanion family) =>
      into(families).insert(family);

  // --- Persons ---
  Future<List<Person>> getPersonsByFamily(String familyId) =>
      (select(persons)..where((p) => p.familyId.equals(familyId))).get();

  Future<void> insertPerson(PersonsCompanion person) =>
      into(persons).insert(person);

  // --- Foods ---
  Future<List<Food>> getFoodsByPerson(String personId) =>
      (select(foods)..where((f) => f.personId.equals(personId))).get();

  Future<void> insertFood(FoodsCompanion food) =>
      into(foods).insert(food);

  Future<void> updateFoodLevel(String foodId, int level) =>
      (update(foods)..where((f) => f.id.equals(foodId)))
          .write(FoodsCompanion(currentLevel: Value(level)));
      
Future<String> getFoodName(String foodId) async {
  final food = await (select(foods)..where((f) => f.id.equals(foodId))).getSingle();
  return food.name;
}
  

  // --- Sessions ---
  Future<List<Session>> getSessionsByPerson(String personId) =>
      (select(sessions)..where((s) => s.personId.equals(personId))).get();

  Future<List<Session>> getSessionsByDate(DateTime date) =>
      (select(sessions)..where((s) => s.date.equals(date))).get();

  Future<List<Session>> getSessionsByPersonAndDate(
      String personId, DateTime date) {
    final nextDay = date.add(const Duration(days: 1));
    return (select(sessions)
          ..where((s) =>
              s.personId.equals(personId) &
              s.date.isBiggerOrEqualValue(date) &
              s.date.isSmallerThanValue(nextDay)))
        .get();
  }
Future<int> getSessionCountForFood(String foodId) async {
  final count = await (selectOnly(sessions)
        ..addColumns([sessions.id.count()])
        ..where(sessions.foodId.equals(foodId)))
      .getSingle();
  return count.read(sessions.id.count()) ?? 0;
}

  Future<void> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<void> completeSession(
      String sessionId, int achievedLevel, String? notes) =>
      (update(sessions)..where((s) => s.id.equals(sessionId))).write(
        SessionsCompanion(
          achievedLevel: Value(achievedLevel),
          notes: Value(notes),
        ),
      );
}