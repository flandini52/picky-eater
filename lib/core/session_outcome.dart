// Mantenuto per compatibilità con dati storici, non più usato attivamente
enum SessionOutcome { success, partial, exceeded }

extension SessionOutcomeExtension on SessionOutcome {
  String get label {
    switch (this) {
      case SessionOutcome.success:
        return 'Obiettivo raggiunto';
      case SessionOutcome.partial:
        return 'Ci ha provato';
      case SessionOutcome.exceeded:
        return 'È andato oltre l\'obiettivo';
    }
  }
}
