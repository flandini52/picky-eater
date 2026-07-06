import 'package:flutter/material.dart';

/// Palette di brand — stile pastello, definita in CLAUDE.md.
/// Da usare al posto di colori hardcoded (es. Colors.orange) in tutta l'app.
class AppColors {
  static const salvia = Color(
    0xFF7BA88C,
  ); // primario: navigazione, pulsanti principali
  static const salviaDark = Color(
    0xFF5E8A70,
  ); // variante scura, per gradienti/depth
  static const pesca = Color(
    0xFFF0997B,
  ); // secondario: illustrazioni, decorazioni cibo
  static const crema = Color(0xFFFBF7EE); // sfondo principale schermate
  static const corallo = Color(
    0xFFD85A30,
  ); // accento CTA e badge premio — con parsimonia

  static const textPrimary = Color(0xFF3D3A34);
  static const textSecondary = Color(0xFF7A756C);
  static const divider = Color(0xFFE4DDD0);
}

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.salvia,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.salvia,
        onPrimary: Colors.white,
        secondary: AppColors.pesca,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.textPrimary,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.crema,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.salvia,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.salvia,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.salvia,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.corallo,
      foregroundColor: Colors.white,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.salvia,
    ),
    dividerColor: AppColors.divider,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
