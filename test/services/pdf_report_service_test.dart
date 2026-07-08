import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:picky_eater/models/food_entity.dart';
import 'package:picky_eater/models/person_entity.dart';
import 'package:picky_eater/models/session_entity.dart';
import 'package:picky_eater/services/pdf_report_service.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  test('generateReport produce un file PDF valido e non vuoto', () async {
    final service = PdfReportService();

    final person = PersonEntity(
      id: 'p1',
      familyId: 'f1',
      name: 'Marco',
      createdAt: DateTime(2026, 1, 1),
    );
    const food = FoodEntity(
      id: 'food1',
      personId: 'p1',
      name: 'Carota',
      category: 'verdura',
      currentLevel: 2,
    );
    final sessions = [
      SessionEntity(
        id: 's1',
        personId: 'p1',
        foodId: 'food1',
        date: DateTime(2026, 1, 10),
        targetLevel: 2,
        activity: 'Annusare a distanza',
        achievedLevel: 2,
        achievedActivity: 'Annusare a distanza',
        notes: 'Buona reazione',
      ),
      SessionEntity(
        id: 's2',
        personId: 'p1',
        foodId: 'food1',
        date: DateTime(2026, 1, 17),
        targetLevel: 3,
      ),
    ];

    const safeFood = FoodEntity(
      id: 'food_safe',
      personId: 'p1',
      name: 'Mela',
      category: 'frutta',
      currentLevel: 5,
      isSafeFood: true,
    );

    final file = await service.generateReport(
      person: person,
      safeFoods: [safeFood],
      foodsData: [FoodReportData(food: food, sessions: sessions)],
    );

    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(0));
    // Firma PDF: ogni file PDF valido inizia con "%PDF-"
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    await file.delete();
  });

  test('generateReport gestisce alimenti senza sessioni', () async {
    final service = PdfReportService();
    final person = PersonEntity(
      id: 'p2',
      familyId: 'f1',
      name: 'Giulia',
      createdAt: DateTime(2026, 1, 1),
    );
    const food = FoodEntity(
      id: 'food2',
      personId: 'p2',
      name: 'Pane',
      category: 'carboidrati',
      currentLevel: 0,
    );

    final file = await service.generateReport(
      person: person,
      safeFoods: const [],
      foodsData: [const FoodReportData(food: food, sessions: [])],
    );

    expect(await file.exists(), isTrue);
    await file.delete();
  });

  test('generateReport gestisce solo safe foods senza alimenti SOS', () async {
    final service = PdfReportService();
    final person = PersonEntity(
      id: 'p3',
      familyId: 'f1',
      name: 'Luca',
      createdAt: DateTime(2026, 1, 1),
    );
    const safeFood = FoodEntity(
      id: 'food3',
      personId: 'p3',
      name: 'Riso',
      category: 'carboidrati',
      currentLevel: 5,
      isSafeFood: true,
    );

    final file = await service.generateReport(
      person: person,
      safeFoods: const [safeFood],
      foodsData: const [],
    );

    expect(await file.exists(), isTrue);
    await file.delete();
  });
}
