import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../main.dart';

class AchievementsScreen extends StatefulWidget {
  final Person person;

  const AchievementsScreen({super.key, required this.person});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Badge> _unlockedBadges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  @override
  void didUpdateWidget(AchievementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != widget.person.id) {
      _loadBadges();
    }
  }

  Future<void> _loadBadges() async {
    setState(() => _loading = true);
    final badges = await database.getBadgesForPerson(widget.person.id);
    setState(() {
      _unlockedBadges = badges;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlockedTypes =
        _unlockedBadges.map((b) => b.badgeType).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Traguardi di ${widget.person.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadBadges,
              color: Colors.orange,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: BadgeType.values.length,
                itemBuilder: (context, index) {
                  final type = BadgeType.values[index];
                  final isUnlocked = unlockedTypes.contains(type.name);
                  final unlockedBadge = isUnlocked
                      ? _unlockedBadges
                          .firstWhere((b) => b.badgeType == type.name)
                      : null;

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
                          ? Icon(Icons.check_circle,
                              color: Colors.green.shade400)
                          : const Icon(Icons.lock_outline,
                              color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
    );
  }
}