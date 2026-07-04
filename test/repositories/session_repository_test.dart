import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picky_eater/database/app_database.dart';
import 'package:picky_eater/providers/database_provider.dart';
import 'package:picky_eater/providers/dashboard_provider.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    await db.insertFamily(
      FamiliesCompanion.insert(id: 'family_1', name: 'Test Family'),
    );
    await db.insertPerson(
      PersonsCompanion.insert(
        id: 'person_1',
        familyId: 'family_1',
        name: 'Test Person',
      ),
    );
    await db.insertFood(
      FoodsCompanion.insert(
        id: 'food_1',
        personId: 'person_1',
        name: 'Carota',
        category: 'verdura',
      ),
    );
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('SessionRepository', () {
    test(
      'insertSession e getSessionsByPerson restituiscono dati corretti',
      () async {
        final repo = container.read(sessionRepositoryProvider);

        await repo.insertSession(
          id: 'session_1',
          personId: 'person_1',
          foodId: 'food_1',
          date: DateTime(2026, 7, 1),
          targetLevel: 2,
          activity: 'Annusare tenendolo in mano',
        );

        final sessions = await repo.getSessionsByPerson('person_1');
        expect(sessions.length, 1);
        expect(sessions.first.foodId, 'food_1');
        expect(sessions.first.targetLevel, 2);
        expect(sessions.first.activity, 'Annusare tenendolo in mano');
        expect(sessions.first.achievedLevel, isNull);
      },
    );

    test(
      'completeSession aggiorna livello raggiunto, attività e note',
      () async {
        final repo = container.read(sessionRepositoryProvider);

        await repo.insertSession(
          id: 'session_1',
          personId: 'person_1',
          foodId: 'food_1',
          date: DateTime(2026, 7, 1),
          targetLevel: 2,
        );

        await repo.completeSession(
          sessionId: 'session_1',
          achievedLevel: 3,
          achievedActivity: 'Toccare con un dito',
          notes: 'Ha reagito bene',
        );

        final sessions = await repo.getSessionsByPerson('person_1');
        expect(sessions.first.achievedLevel, 3);
        expect(sessions.first.achievedActivity, 'Toccare con un dito');
        expect(sessions.first.notes, 'Ha reagito bene');
      },
    );

    test(
      'getCompletedSessionsForFood restituisce solo le sessioni completate',
      () async {
        final repo = container.read(sessionRepositoryProvider);

        await repo.insertSession(
          id: 'session_planned',
          personId: 'person_1',
          foodId: 'food_1',
          date: DateTime(2026, 7, 1),
          targetLevel: 1,
        );
        await repo.insertSession(
          id: 'session_completed',
          personId: 'person_1',
          foodId: 'food_1',
          date: DateTime(2026, 7, 2),
          targetLevel: 1,
        );
        await repo.completeSession(
          sessionId: 'session_completed',
          achievedLevel: 1,
        );

        final completed = await repo.getCompletedSessionsForFood('food_1');
        expect(completed.length, 1);
        expect(completed.first.id, 'session_completed');
      },
    );
  });
}
