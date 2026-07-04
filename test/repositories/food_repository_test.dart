import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picky_eater/database/app_database.dart';
import 'package:picky_eater/providers/database_provider.dart';
import 'package:picky_eater/providers/dashboard_provider.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('FoodRepository', () {
    test('insertFood e getFoodsByPerson restituiscono dati corretti', () async {
      final repo = container.read(foodRepositoryProvider);

      // Prima serve una famiglia e una persona
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

      await repo.insertFood(
        id: 'food_1',
        personId: 'person_1',
        name: 'Carota',
        category: 'verdura',
      );

      final foods = await repo.getFoodsByPerson('person_1');
      expect(foods.length, 1);
      expect(foods.first.name, 'Carota');
      expect(foods.first.category, 'verdura');
      expect(foods.first.currentLevel, 0);
    });

    test('updateFoodLevel aggiorna il livello correttamente', () async {
      final repo = container.read(foodRepositoryProvider);

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
      await repo.insertFood(
        id: 'food_1',
        personId: 'person_1',
        name: 'Carota',
        category: 'verdura',
      );

      await repo.updateFoodLevel('food_1', 3);

      final foods = await repo.getFoodsByPerson('person_1');
      expect(foods.first.currentLevel, 3);
    });

    test('deleteFood rimuove alimento e sessioni collegate', () async {
      final repo = container.read(foodRepositoryProvider);

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
      await repo.insertFood(
        id: 'food_1',
        personId: 'person_1',
        name: 'Carota',
        category: 'verdura',
      );

      // Inserisci una sessione collegata
      await db.insertSession(
        SessionsCompanion.insert(
          id: 'session_1',
          personId: 'person_1',
          foodId: 'food_1',
          date: DateTime.now(),
          targetLevel: 0,
        ),
      );

      await repo.deleteFood('food_1');

      final foods = await repo.getFoodsByPerson('person_1');
      expect(foods, isEmpty);

      // Verifica che la sessione sia stata eliminata in cascata
      final sessions = await db.getSessionsByPerson('person_1');
      expect(sessions, isEmpty);
    });
  });
}
