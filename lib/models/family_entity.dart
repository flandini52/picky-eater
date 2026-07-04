class FamilyEntity {
  final String id;
  final String name;

  const FamilyEntity({required this.id, required this.name});

  FamilyEntity copyWith({String? id, String? name}) {
    return FamilyEntity(id: id ?? this.id, name: name ?? this.name);
  }
}
