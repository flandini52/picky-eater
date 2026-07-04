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
  );

  Future<List<FoodEntity>> getFoodsByPerson(String personId) async {
    final foods = await _db.getFoodsByPerson(personId);
    return foods.map(_toEntity).toList();
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
  }) => _db.insertFood(
    FoodsCompanion.insert(
      id: id,
      personId: personId,
      name: name,
      category: category,
      currentLevel: Value(currentLevel),
    ),
  );

  Future<void> updateFood({
    required String foodId,
    required String name,
    required String category,
  }) => _db.updateFood(foodId, name, category);

  Future<void> updateFoodLevel(String foodId, int level) =>
      _db.updateFoodLevel(foodId, level);

  Future<void> deleteFood(String foodId) => _db.deleteFood(foodId);

  Future<int> getSessionCountForFood(String foodId) =>
      _db.getSessionCountForFood(foodId);
}
