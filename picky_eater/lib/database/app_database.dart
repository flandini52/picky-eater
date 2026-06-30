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

const Map<ExposureLevel, List<String>> levelActivities = {
  ExposureLevel.tolerates: [
    'Stare nella stessa stanza con il cibo',
    'Sedersi al tavolo con il cibo presente',
    'A tavola guardare il cibo da lontano',
  ],
  ExposureLevel.interacts: [
    'Spostare il cibo nel piatto con un cucchiaio',
    'Aiutare a preparare il cibo',
    'Usare una forchetta per toccare il cibo',
  ],
  ExposureLevel.smells: [
    'Annusare il cibo a distanza / percepisce odore nella stanza',
    'Si avvicina e annusa',
    'Annusare tenendolo in mano',
  ],
  ExposureLevel.touches: [
    'Toccare con le posate',
    'Toccare con un dito',
    'Toccare con tutta la mano',
  ],
  ExposureLevel.tastes: [
    'Portare alle labbra',
    'Toccare con la punta della lingua',
    'Lecca ma non mette in bocca',
  ],
  ExposureLevel.eats: [
    'Masticare e sputare',
    'Masticare e deglutire',
    'Mangiare autonomamente',
  ],
};

enum BadgeType {
  firstSession,
  firstTaste,
  firstEat,
  foodCompleted,
  fiveFoodsTriedDifferent,
  tenSessionsTotal,
}

extension BadgeTypeExtension on BadgeType {
  String get title {
    switch (this) {
      case BadgeType.firstSession:
        return 'Prima sessione';
      case BadgeType.firstTaste:
        return 'Primo assaggio';
      case BadgeType.firstEat:
        return 'Prima volta che mangia!';
      case BadgeType.foodCompleted:
        return 'Percorso completato';
      case BadgeType.fiveFoodsTriedDifferent:
        return '5 alimenti provati';
      case BadgeType.tenSessionsTotal:
        return '10 sessioni registrate';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeType.firstSession:
        return '🎉';
      case BadgeType.firstTaste:
        return '👅';
      case BadgeType.firstEat:
        return '🍽️';
      case BadgeType.foodCompleted:
        return '🌟';
      case BadgeType.fiveFoodsTriedDifferent:
        return '🥗';
      case BadgeType.tenSessionsTotal:
        return '📅';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.firstSession:
        return 'Hai registrato la tua prima sessione!';
      case BadgeType.firstTaste:
        return 'Un alimento è stato assaggiato per la prima volta!';
      case BadgeType.firstEat:
        return 'Un alimento è stato mangiato per la prima volta!';
      case BadgeType.foodCompleted:
        return 'Un alimento ha completato tutto il percorso, da Tollera a Mangia!';
      case BadgeType.fiveFoodsTriedDifferent:
        return 'Hai provato 5 alimenti diversi!';
      case BadgeType.tenSessionsTotal:
        return 'Hai registrato 10 sessioni in totale!';
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
  TextColumn get activity => text().nullable()(); // NUOVO
  IntColumn get achievedLevel => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WeeklyGoals extends Table {
  TextColumn get personId => text().references(Persons, #id)();
  IntColumn get targetSessions => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {personId};
}

class Badges extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(Persons, #id)();
  TextColumn get badgeType => text()(); // es. 'first_session', 'first_taste', ecc.
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(tables: [Families, Persons, Foods, Sessions, WeeklyGoals, Badges])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'picky_eater_db');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(sessions, sessions.activity);
          }
          if (from < 3) {
            await m.createTable(weeklyGoals);
            await m.createTable(badges);
          }
        },
      );

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

  // --- Weekly Goals ---
  Future<int> getWeeklyGoal(String personId) async {
    final goal = await (select(weeklyGoals)
          ..where((g) => g.personId.equals(personId)))
        .getSingleOrNull();
    return goal?.targetSessions ?? 3;
  }

  Future<void> setWeeklyGoal(String personId, int target) async {
    await into(weeklyGoals).insertOnConflictUpdate(
      WeeklyGoalsCompanion.insert(
        personId: personId,
        targetSessions: Value(target),
      ),
    );
  }

  Future<int> getSessionsThisWeek(String personId) async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final count = await (selectOnly(sessions)
          ..addColumns([sessions.id.count()])
          ..where(sessions.personId.equals(personId) &
              sessions.date.isBiggerOrEqualValue(monday)))
        .getSingle();
    return count.read(sessions.id.count()) ?? 0;
  }

  // --- Badges ---
  Future<List<Badge>> getBadgesForPerson(String personId) =>
      (select(badges)..where((b) => b.personId.equals(personId))).get();

  Future<bool> hasBadge(String personId, BadgeType type) async {
    final existing = await (select(badges)
          ..where((b) =>
              b.personId.equals(personId) & b.badgeType.equals(type.name)))
        .getSingleOrNull();
    return existing != null;
  }

  Future<void> unlockBadge(String personId, BadgeType type) async {
    final already = await hasBadge(personId, type);
    if (already) return;
    await into(badges).insert(
      BadgesCompanion.insert(
        id: '${personId}_${type.name}',
        personId: personId,
        badgeType: type.name,
        unlockedAt: DateTime.now(),
      ),
    );
  }

  // Controlla e sblocca eventuali badge dopo una sessione completata
  Future<List<BadgeType>> checkAndUnlockBadges(
      String personId, String foodId, int achievedLevel) async {
    final List<BadgeType> newlyUnlocked = [];

    // Prima sessione in assoluto
    final totalSessions = await (selectOnly(sessions)
          ..addColumns([sessions.id.count()])
          ..where(sessions.personId.equals(personId) &
              sessions.achievedLevel.isNotNull()))
        .getSingle();
    final sessionCount = totalSessions.read(sessions.id.count()) ?? 0;

    if (sessionCount == 1 && !await hasBadge(personId, BadgeType.firstSession)) {
      await unlockBadge(personId, BadgeType.firstSession);
      newlyUnlocked.add(BadgeType.firstSession);
    }

    if (sessionCount >= 10 &&
        !await hasBadge(personId, BadgeType.tenSessionsTotal)) {
      await unlockBadge(personId, BadgeType.tenSessionsTotal);
      newlyUnlocked.add(BadgeType.tenSessionsTotal);
    }

    // Primo assaggio o primo "mangia" raggiunto
    if (achievedLevel == ExposureLevel.tastes.index &&
        !await hasBadge(personId, BadgeType.firstTaste)) {
      await unlockBadge(personId, BadgeType.firstTaste);
      newlyUnlocked.add(BadgeType.firstTaste);
    }
    if (achievedLevel == ExposureLevel.eats.index) {
      if (!await hasBadge(personId, BadgeType.firstEat)) {
        await unlockBadge(personId, BadgeType.firstEat);
        newlyUnlocked.add(BadgeType.firstEat);
      }
      if (!await hasBadge(personId, BadgeType.foodCompleted)) {
        await unlockBadge(personId, BadgeType.foodCompleted);
        newlyUnlocked.add(BadgeType.foodCompleted);
      }
    }

    // 5 alimenti diversi provati (almeno una sessione completata)
    final foodsWithSessions = await (selectOnly(sessions)
          ..addColumns([sessions.foodId])
          ..where(sessions.personId.equals(personId) &
              sessions.achievedLevel.isNotNull())
          ..groupBy([sessions.foodId]))
        .get();
    if (foodsWithSessions.length >= 5 &&
        !await hasBadge(personId, BadgeType.fiveFoodsTriedDifferent)) {
      await unlockBadge(personId, BadgeType.fiveFoodsTriedDifferent);
      newlyUnlocked.add(BadgeType.fiveFoodsTriedDifferent);
    }

    return newlyUnlocked;
  }
}