import 'package:flutter/material.dart';

/// Sotto-palette pastello per categoria alimento — puramente decorativa
/// (aiuto visivo di raggruppamento), volutamente distinta dagli accenti
/// di stato (verde/ambra/blu/rosso) usati per l'esito delle sessioni.
const Map<String, Color> foodCategoryColors = {
  'frutta': Color(0xFFE8B4AE), // rosa cipria
  'verdura': Color(0xFFA8C3AD), // verde salvia chiaro
  'carne': Color(0xFFD99B85), // terracotta chiaro
  'pesce': Color(0xFFA8C0CC), // azzurro polvere
  'carboidrati': Color(0xFFE0C9A0), // sabbia
  'latticini': Color(0xFFC7B8D9), // lavanda
  'dolci': Color(0xFFBFA0AC), // malva
};

const Color defaultCategoryColor = Color(
  0xFFC9C4BC,
); // neutro, categoria sconosciuta

extension FoodCategoryColorExtension on String {
  Color get categoryColor =>
      foodCategoryColors[toLowerCase()] ?? defaultCategoryColor;
}
