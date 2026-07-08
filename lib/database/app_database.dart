import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../core/badge_type.dart';
import '../core/exposure_level.dart';

part 'app_database.g.dart';

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
  IntColumn get avatarColor =>
      integer().withDefault(const Constant(0xFFFF9800))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(Persons, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get currentLevel => integer().withDefault(const Constant(0))();
  BoolColumn get isSafeFood => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(Persons, #id)();
  TextColumn get foodId => text().references(Foods, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get targetLevel => integer()();
  TextColumn get activity => text().nullable()();
  IntColumn get achievedLevel => integer().nullable()();
  TextColumn get achievedActivity =>
      text().nullable()(); // NUOVO: attività SOS specifica raggiunta
  TextColumn get outcome =>
      text().nullable()(); // legacy, non più scritto attivamente
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
  TextColumn get badgeType =>
      text()(); // es. 'first_session', 'first_taste', ecc.
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(
  tables: [Families, Persons, Foods, Sessions, WeeklyGoals, Badges],
)
class AppDatabase extends _$AppDatabase {
  /// Costruttore di produzione — usa SQLite reale via driftDatabase
  AppDatabase() : super(_openConnection());

  /// Costruttore per i test — accetta un executor in-memory
  /// Non usare mai in produzione
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

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
      if (from < 4) {
        await m.addColumn(sessions, sessions.outcome);
      }
      if (from < 5) {
        await m.addColumn(sessions, sessions.achievedActivity);
      }
      if (from < 6) {
        await m.addColumn(foods, foods.isSafeFood);
      }
      if (from < 7) {
        await m.addColumn(persons, persons.createdAt);
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

  Future<void> updatePersonName(String personId, String name) =>
      (update(persons)..where((p) => p.id.equals(personId))).write(
        PersonsCompanion(name: Value(name)),
      );

  Future<void> deletePerson(String personId) async {
    // Elimina tutti i dati collegati per evitare dati orfani
    final personFoods = await getFoodsByPerson(personId);
    for (final food in personFoods) {
      await (delete(sessions)..where((s) => s.foodId.equals(food.id))).go();
    }
    await (delete(foods)..where((f) => f.personId.equals(personId))).go();
    await (delete(badges)..where((b) => b.personId.equals(personId))).go();
    await (delete(weeklyGoals)..where((g) => g.personId.equals(personId))).go();
    await (delete(persons)..where((p) => p.id.equals(personId))).go();
  }

  // --- Foods ---
  Future<List<Food>> getFoodsByPerson(String personId) =>
      (select(foods)..where((f) => f.personId.equals(personId))).get();

  Future<void> insertFood(FoodsCompanion food) => into(foods).insert(food);

  Future<void> updateFood(String foodId, String name, String category) =>
      (update(foods)..where((f) => f.id.equals(foodId))).write(
        FoodsCompanion(name: Value(name), category: Value(category)),
      );

  Future<void> deleteFood(String foodId) async {
    // Elimina prima le sessioni collegate per evitare dati orfani
    await (delete(sessions)..where((s) => s.foodId.equals(foodId))).go();
    await (delete(foods)..where((f) => f.id.equals(foodId))).go();
  }

  Future<void> updateFoodLevel(String foodId, int level) =>
      (update(foods)..where((f) => f.id.equals(foodId))).write(
        FoodsCompanion(currentLevel: Value(level)),
      );

  Future<void> setSafeFood(String foodId, bool isSafeFood) =>
      (update(foods)..where((f) => f.id.equals(foodId))).write(
        FoodsCompanion(isSafeFood: Value(isSafeFood)),
      );

  Future<String> getFoodName(String foodId) async {
    final food = await (select(
      foods,
    )..where((f) => f.id.equals(foodId))).getSingle();
    return food.name;
  }

  // --- Sessions ---
  Future<List<Session>> getSessionsByPerson(String personId) =>
      (select(sessions)..where((s) => s.personId.equals(personId))).get();

  Future<List<Session>> getSessionsByDate(DateTime date) =>
      (select(sessions)..where((s) => s.date.equals(date))).get();

  Future<List<Session>> getSessionsByPersonAndDate(
    String personId,
    DateTime date,
  ) {
    final nextDay = date.add(const Duration(days: 1));
    return (select(sessions)..where(
          (s) =>
              s.personId.equals(personId) &
              s.date.isBiggerOrEqualValue(date) &
              s.date.isSmallerThanValue(nextDay),
        ))
        .get();
  }

  /// [to] esclusivo — passare il primo giorno del mese successivo per
  /// includere anche l'ultimo giorno del mese richiesto.
  Future<List<Session>> getSessionsByPersonAndDateRange(
    String personId,
    DateTime from,
    DateTime to,
  ) {
    return (select(sessions)..where(
          (s) =>
              s.personId.equals(personId) &
              s.date.isBiggerOrEqualValue(from) &
              s.date.isSmallerThanValue(to),
        ))
        .get();
  }

  Future<int> getSessionCountForFood(String foodId) async {
    final count =
        await (selectOnly(sessions)
              ..addColumns([sessions.id.count()])
              ..where(sessions.foodId.equals(foodId)))
            .getSingle();
    return count.read(sessions.id.count()) ?? 0;
  }

  Future<void> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<void> completeSession(
    String sessionId,
    int achievedLevel,
    String? achievedActivity,
    String? notes,
  ) => (update(sessions)..where((s) => s.id.equals(sessionId))).write(
    SessionsCompanion(
      achievedLevel: Value(achievedLevel),
      achievedActivity: Value(achievedActivity),
      notes: Value(notes),
    ),
  );
  Future<DateTime?> getLastCompletedSessionDate(String personId) async {
    final session =
        await (select(sessions)
              ..where(
                (s) =>
                    s.personId.equals(personId) & s.achievedLevel.isNotNull(),
              )
              ..orderBy([(s) => OrderingTerm.desc(s.date)])
              ..limit(1))
            .getSingleOrNull();
    return session?.date;
  }

  Future<List<Session>> getCompletedSessionsForFood(String foodId) async {
    return (select(sessions)
          ..where((s) => s.foodId.equals(foodId) & s.achievedLevel.isNotNull())
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
  }

  Future<List<Session>> getCompletedSessionsForPerson(String personId) async {
    return (select(sessions)
          ..where(
            (s) => s.personId.equals(personId) & s.achievedLevel.isNotNull(),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
  }

  Future<int> getSessionsThisMonth(String personId) async {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final firstOfNextMonth = DateTime(now.year, now.month + 1, 1);

    final count =
        await (selectOnly(sessions)
              ..addColumns([sessions.id.count()])
              ..where(
                sessions.personId.equals(personId) &
                    sessions.achievedLevel.isNotNull() &
                    sessions.date.isBiggerOrEqualValue(firstOfMonth) &
                    sessions.date.isSmallerThanValue(firstOfNextMonth),
              ))
            .getSingle();
    return count.read(sessions.id.count()) ?? 0;
  }

  // --- Weekly Goals ---
  Future<int> getWeeklyGoal(String personId) async {
    final goal = await (select(
      weeklyGoals,
    )..where((g) => g.personId.equals(personId))).getSingleOrNull();
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
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final count =
        await (selectOnly(sessions)
              ..addColumns([sessions.id.count()])
              ..where(
                sessions.personId.equals(personId) &
                    sessions.date.isBiggerOrEqualValue(monday),
              ))
            .getSingle();
    return count.read(sessions.id.count()) ?? 0;
  }

  // --- Badges ---
  Future<List<Badge>> getBadgesForPerson(String personId) =>
      (select(badges)..where((b) => b.personId.equals(personId))).get();

  Future<bool> hasBadge(String personId, BadgeType type) async {
    final existing =
        await (select(badges)..where(
              (b) =>
                  b.personId.equals(personId) & b.badgeType.equals(type.name),
            ))
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
    String personId,
    String foodId,
    int achievedLevel,
  ) async {
    final List<BadgeType> newlyUnlocked = [];

    // Prima sessione in assoluto
    final totalSessions =
        await (selectOnly(sessions)
              ..addColumns([sessions.id.count()])
              ..where(
                sessions.personId.equals(personId) &
                    sessions.achievedLevel.isNotNull(),
              ))
            .getSingle();
    final sessionCount = totalSessions.read(sessions.id.count()) ?? 0;

    if (sessionCount == 1 &&
        !await hasBadge(personId, BadgeType.firstSession)) {
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
    final foodsWithSessions =
        await (selectOnly(sessions)
              ..addColumns([sessions.foodId])
              ..where(
                sessions.personId.equals(personId) &
                    sessions.achievedLevel.isNotNull(),
              )
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
