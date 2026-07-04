class BadgeEntity {
  final String id;
  final String personId;
  final String badgeType;
  final DateTime unlockedAt;

  const BadgeEntity({
    required this.id,
    required this.personId,
    required this.badgeType,
    required this.unlockedAt,
  });
}
