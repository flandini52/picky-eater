class PersonEntity {
  final String id;
  final String familyId;
  final String name;
  final DateTime? birthDate;
  final int avatarColor;
  final DateTime? createdAt;

  const PersonEntity({
    required this.id,
    required this.familyId,
    required this.name,
    this.birthDate,
    this.avatarColor = 0xFFFF9800,
    this.createdAt,
  });

  PersonEntity copyWith({
    String? id,
    String? familyId,
    String? name,
    DateTime? birthDate,
    int? avatarColor,
    DateTime? createdAt,
  }) {
    return PersonEntity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      avatarColor: avatarColor ?? this.avatarColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
