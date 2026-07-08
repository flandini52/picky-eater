import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/person_entity.dart';

class PersonRepository {
  final AppDatabase _db;

  PersonRepository(this._db);

  PersonEntity _toEntity(Person person) => PersonEntity(
    id: person.id,
    familyId: person.familyId,
    name: person.name,
    birthDate: person.birthDate,
    avatarColor: person.avatarColor,
    createdAt: person.createdAt,
  );

  Future<List<PersonEntity>> getPersonsByFamily(String familyId) async {
    final persons = await _db.getPersonsByFamily(familyId);
    return persons.map(_toEntity).toList();
  }

  Future<void> insertPerson({
    required String id,
    required String familyId,
    required String name,
  }) => _db.insertPerson(
    PersonsCompanion.insert(
      id: id,
      familyId: familyId,
      name: name,
      createdAt: Value(DateTime.now()),
    ),
  );

  Future<void> updatePersonName(String personId, String name) =>
      _db.updatePersonName(personId, name);

  Future<void> deletePerson(String personId) => _db.deletePerson(personId);
}
