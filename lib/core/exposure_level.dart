enum ExposureLevel { tolerates, interacts, smells, touches, tastes, eats }

extension ExposureLevelExtension on ExposureLevel {
  String get label {
    switch (this) {
      case ExposureLevel.tolerates:
        return '🔴 Tollera';
      case ExposureLevel.interacts:
        return '🟠 Interagisce';
      case ExposureLevel.smells:
        return '🟡 Annusa';
      case ExposureLevel.touches:
        return '🟢 Tocca';
      case ExposureLevel.tastes:
        return '🔵 Assaggia';
      case ExposureLevel.eats:
        return '⭐ Mangia';
    }
  }

  String get description {
    switch (this) {
      case ExposureLevel.tolerates:
        return 'È nella stessa stanza con il cibo';
      case ExposureLevel.interacts:
        return 'Usa utensili o tocca il cibo con strumenti';
      case ExposureLevel.smells:
        return 'Si avvicina e annusa il cibo';
      case ExposureLevel.touches:
        return 'Tocca il cibo con dita, mano o viso';
      case ExposureLevel.tastes:
        return 'Porta il cibo alle labbra o punta della lingua';
      case ExposureLevel.eats:
        return 'Mastica e deglutisce';
    }
  }
}

const Map<ExposureLevel, List<String>> levelActivities = {
  ExposureLevel.tolerates: [
    'Stare nella stessa stanza con il cibo',
    'Sedersi al tavolo con il cibo presente',
    'A tavola guardare il cibo da lontano',
  ],
  ExposureLevel.interacts: [
    'Spostare il cibo nel piatto con un cucchiaio',
    'Aiutare a preparare il cibo',
    'Usare una forchetta per toccare il cibo',
  ],
  ExposureLevel.smells: [
    'Annusare il cibo a distanza / percepisce odore nella stanza',
    'Si avvicina e annusa',
    'Annusare tenendolo in mano',
  ],
  ExposureLevel.touches: [
    'Toccare con le posate',
    'Toccare con un dito',
    'Toccare con tutta la mano',
  ],
  ExposureLevel.tastes: [
    'Portare alle labbra',
    'Toccare con la punta della lingua',
    'Lecca ma non mette in bocca',
  ],
  ExposureLevel.eats: [
    'Masticare e sputare',
    'Masticare e deglutire',
    'Mangiare autonomamente',
  ],
};

/// Calcola l'indice granulare (0-17) di un'attività specifica.
/// Restituisce -1 se non trovata.
int granularIndexForActivity(String? activity) {
  if (activity == null) return -1;
  for (final level in ExposureLevel.values) {
    final activities = levelActivities[level] ?? [];
    final pos = activities.indexOf(activity);
    if (pos != -1) {
      return level.index * 3 + pos;
    }
  }
  return -1;
}

/// Etichetta breve per un indice granulare, utile per i grafici
String granularLabel(int granularIndex) {
  final levelIndex = granularIndex ~/ 3;
  if (levelIndex < 0 || levelIndex >= ExposureLevel.values.length) return '';
  return ExposureLevel.values[levelIndex].label;
}
