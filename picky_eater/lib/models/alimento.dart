enum ExposureLevel {
  totalRefusal,
  toleratesPresence,
  looks,
  touches,
  tastes,
}

extension ExposureLevelExtension on ExposureLevel {
  String get label {
    switch (this) {
      case ExposureLevel.totalRefusal:
        return '🔴 Rifiuto totale';
      case ExposureLevel.toleratesPresence:
        return '🟠 Tollera la presenza';
      case ExposureLevel.looks:
        return '🟡 Guarda';
      case ExposureLevel.touches:
        return '🟢 Tocca';
      case ExposureLevel.tastes:
        return '✅ Assaggia';
    }
  }
}

class Food {
  final String id;
  final String name;
  final String category; // es. "frutta", "verdura", "carne"
  ExposureLevel level;

  Food({
    required this.id,
    required this.name,
    required this.category,
    this.level = ExposureLevel.totalRefusal,
  });
}