import 'package:flutter/material.dart';

/// Badge testuale tenue che mostra l'esito di una sessione
/// confrontando il livello raggiunto con quello obiettivo.
class OutcomeBadge extends StatelessWidget {
  final int targetLevel;
  final int achievedLevel;

  const OutcomeBadge({
    super.key,
    required this.targetLevel,
    required this.achievedLevel,
  });

  Color get _bg {
    if (achievedLevel > targetLevel) return Colors.blue.shade50;
    if (achievedLevel == targetLevel) return Colors.green.shade50;
    return Colors.amber.shade50;
  }

  Color get _fg {
    if (achievedLevel > targetLevel) return Colors.blue.shade700;
    if (achievedLevel == targetLevel) return Colors.green.shade700;
    return Colors.amber.shade800;
  }

  String get _text {
    if (achievedLevel > targetLevel) return 'Andato oltre l\'obiettivo';
    if (achievedLevel == targetLevel) return 'Obiettivo raggiunto';
    return 'Ci ha provato';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _text,
        style: TextStyle(fontSize: 10, color: _fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
