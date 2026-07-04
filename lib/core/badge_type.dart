enum BadgeType {
  firstSession,
  firstTaste,
  firstEat,
  foodCompleted,
  fiveFoodsTriedDifferent,
  tenSessionsTotal,
}

extension BadgeTypeExtension on BadgeType {
  String get title {
    switch (this) {
      case BadgeType.firstSession:
        return 'Prima sessione';
      case BadgeType.firstTaste:
        return 'Primo assaggio';
      case BadgeType.firstEat:
        return 'Prima volta che mangia!';
      case BadgeType.foodCompleted:
        return 'Percorso completato';
      case BadgeType.fiveFoodsTriedDifferent:
        return '5 alimenti provati';
      case BadgeType.tenSessionsTotal:
        return '10 sessioni registrate';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeType.firstSession:
        return '🎉';
      case BadgeType.firstTaste:
        return '👅';
      case BadgeType.firstEat:
        return '🍽️';
      case BadgeType.foodCompleted:
        return '🌟';
      case BadgeType.fiveFoodsTriedDifferent:
        return '🥗';
      case BadgeType.tenSessionsTotal:
        return '📅';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.firstSession:
        return 'Hai registrato la tua prima sessione!';
      case BadgeType.firstTaste:
        return 'Un alimento è stato assaggiato per la prima volta!';
      case BadgeType.firstEat:
        return 'Un alimento è stato mangiato per la prima volta!';
      case BadgeType.foodCompleted:
        return 'Un alimento ha completato tutto il percorso, da Tollera a Mangia!';
      case BadgeType.fiveFoodsTriedDifferent:
        return 'Hai provato 5 alimenti diversi!';
      case BadgeType.tenSessionsTotal:
        return 'Hai registrato 10 sessioni in totale!';
    }
  }
}
