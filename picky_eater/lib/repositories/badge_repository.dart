import '../database/app_database.dart';
import '../models/badge_entity.dart';

class BadgeRepository {
  final AppDatabase _db;

  BadgeRepository(this._db);

  BadgeEntity _toEntity(Badge badge) => BadgeEntity(
        id: badge.id,
        personId: badge.personId,
        badgeType: badge.badgeType,
        unlockedAt: badge.unlockedAt,
      );

  Future<List<BadgeEntity>> getBadgesForPerson(String personId) async {
    final badges = await _db.getBadgesForPerson(personId);
    return badges.map(_toEntity).toList();
  }

  Future<bool> hasBadge(String personId, BadgeType type) =>
      _db.hasBadge(personId, type);

  Future<void> unlockBadge(String personId, BadgeType type) =>
      _db.unlockBadge(personId, type);

  Future<List<BadgeType>> checkAndUnlockBadges(
    String personId,
    String foodId,
    int achievedLevel,
  ) =>
      _db.checkAndUnlockBadges(personId, foodId, achievedLevel);
}