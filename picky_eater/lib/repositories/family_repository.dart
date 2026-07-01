import '../database/app_database.dart';
import '../models/family_entity.dart';

class FamilyRepository {
  final AppDatabase _db;

  FamilyRepository(this._db);

  FamilyEntity _toEntity(Family family) => FamilyEntity(
        id: family.id,
        name: family.name,
      );

  Future<List<FamilyEntity>> getAllFamilies() async {
    final families = await _db.getAllFamilies();
    return families.map(_toEntity).toList();
  }

  Future<void> insertFamily({
    required String id,
    required String name,
  }) =>
      _db.insertFamily(FamiliesCompanion.insert(
        id: id,
        name: name,
      ));
}