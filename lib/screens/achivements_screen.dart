import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/badge_type.dart';
import '../database/app_database.dart';
import '../models/badge_entity.dart';
import '../providers/calendar_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  final Person person;

  const AchievementsScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeRepo = ref.watch(badgeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Traguardi di ${person.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<BadgeEntity>>(
        future: badgeRepo.getBadgesForPerson(person.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          final unlockedTypes = snapshot.data!.map((b) => b.badgeType).toSet();

          return RefreshIndicator(
            onRefresh: () async {
              (context as Element).markNeedsBuild();
            },
            color: Colors.orange,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: BadgeType.values.length,
              itemBuilder: (context, index) {
                final type = BadgeType.values[index];
                final isUnlocked = unlockedTypes.contains(type.name);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isUnlocked ? 3 : 0,
                  color: isUnlocked ? Colors.white : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isUnlocked
                          ? Colors.orange.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Opacity(
                      opacity: isUnlocked ? 1.0 : 0.3,
                      child: Text(
                        type.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    title: Text(
                      type.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      type.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                    ),
                    trailing: isUnlocked
                        ? Icon(Icons.check_circle, color: Colors.green.shade400)
                        : const Icon(Icons.lock_outline, color: Colors.grey),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
