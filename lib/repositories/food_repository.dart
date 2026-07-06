import '../database/app_database.dart';
import '../models/food_entity.dart';
import 'package:drift/drift.dart';

class FoodRepository {
  final AppDatabase _db;

  FoodRepository(this._db);

  // Mapper Drift → dominio
  FoodEntity _toEntity(Food food) => FoodEntity(
    id: food.id,
    personId: food.personId,
    name: food.name,
    category: food.category,
    currentLevel: food.currentLevel,
    isSafeFood: food.isSafeFood,
  );

  /// Restituisce tutti gli alimenti della persona, sia safe food che in
  /// percorso SOS. Usa [getSafeFoodsByPerson]/[getSosFoodsByPerson] quando
  /// serve distinguere le due categorie.
  Future<List<FoodEntity>> getFoodsByPerson(String personId) async {
    final foods = await _db.getFoodsByPerson(personId);
    return foods.map(_toEntity).toList();
  }

  /// Solo gli alimenti già marcati come safe food.
  Future<List<FoodEntity>> getSafeFoodsByPerson(String personId) async {
    final foods = await getFoodsByPerson(personId);
    return foods.where((f) => f.isSafeFood).toList();
  }

  /// Solo gli alimenti ancora in percorso SOS (isSafeFood == false).
  Future<List<FoodEntity>> getSosFoodsByPerson(String personId) async {
    final foods = await getFoodsByPerson(personId);
    return foods.where((f) => !f.isSafeFood).toList();
  }

  Future<FoodEntity?> getFoodById(String foodId) async {
    try {
      final food = await (_db.select(
        _db.foods,
      )..where((f) => f.id.equals(foodId))).getSingle();
      return _toEntity(food);
    } catch (_) {
      return null;
    }
  }

  Future<void> insertFood({
    required String id,
    required String personId,
    required String name,
    required String category,
    int currentLevel = 0,
    bool isSafeFood = false,
  }) => _db.insertFood(
    FoodsCompanion.insert(
      id: id,
      personId: personId,
      name: name,
      category: category,
      currentLevel: Value(currentLevel),
      isSafeFood: Value(isSafeFood),
    ),
  );

  Future<void> updateFood({
    required String foodId,
    required String name,
    required String category,
  }) => _db.updateFood(foodId, name, category);

  Future<void> updateFoodLevel(String foodId, int level) =>
      _db.updateFoodLevel(foodId, level);

  Future<void> setSafeFood(String foodId, bool isSafeFood) =>
      _db.setSafeFood(foodId, isSafeFood);

  Future<void> deleteFood(String foodId) => _db.deleteFood(foodId);

  Future<int> getSessionCountForFood(String foodId) =>
      _db.getSessionCountForFood(foodId);
}
