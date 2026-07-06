class FoodEntity {
  final String id;
  final String personId;
  final String name;
  final String category;
  final int currentLevel;
  final bool isSafeFood;

  const FoodEntity({
    required this.id,
    required this.personId,
    required this.name,
    required this.category,
    required this.currentLevel,
    this.isSafeFood = false,
  });

  FoodEntity copyWith({
    String? id,
    String? personId,
    String? name,
    String? category,
    int? currentLevel,
    bool? isSafeFood,
  }) {
    return FoodEntity(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      category: category ?? this.category,
      currentLevel: currentLevel ?? this.currentLevel,
      isSafeFood: isSafeFood ?? this.isSafeFood,
    );
  }
}
