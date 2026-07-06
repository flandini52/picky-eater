import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_entity.dart';
import '../models/person_entity.dart';
import '../models/session_entity.dart';
import '../services/pdf_report_service.dart';
import 'dashboard_provider.dart';
import 'person_provider.dart';

export '../services/pdf_report_service.dart' show FoodReportData;

final pdfReportServiceProvider = Provider<PdfReportService>(
  (ref) => PdfReportService(),
);

/// Dati già pronti per l'anteprima e la generazione del report.
class PdfReportViewData {
  final PersonEntity person;
  final List<FoodEntity> safeFoods;
  final List<FoodReportData> foodsData;

  const PdfReportViewData({
    required this.person,
    required this.safeFoods,
    required this.foodsData,
  });
}

class PdfReportNotifier extends FamilyAsyncNotifier<PdfReportViewData, String> {
  @override
  Future<PdfReportViewData> build(String personId) async {
    final familyState = await ref.watch(familyProvider.future);
    final person = familyState.persons.firstWhere((p) => p.id == personId);

    final foodRepo = ref.read(foodRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);

    final safeFoods = await foodRepo.getSafeFoodsByPerson(personId);
    final sosFoods = await foodRepo.getSosFoodsByPerson(personId);
    final allSessions = await sessionRepo.getSessionsByPerson(personId);

    final sessionsByFood = <String, List<SessionEntity>>{};
    for (final session in allSessions) {
      sessionsByFood.putIfAbsent(session.foodId, () => []).add(session);
    }

    // Solo gli alimenti in percorso SOS entrano nella sezione progressi:
    // i safe food hanno già la loro sezione dedicata nel report.
    final foodsData = sosFoods
        .map(
          (food) => FoodReportData(
            food: food,
            sessions: sessionsByFood[food.id] ?? [],
          ),
        )
        .toList();

    return PdfReportViewData(
      person: person,
      safeFoods: safeFoods,
      foodsData: foodsData,
    );
  }

  /// Genera il PDF a partire dai dati già caricati e restituisce il file.
  Future<File> generatePdf() async {
    final data = await future;
    final service = ref.read(pdfReportServiceProvider);
    return service.generateReport(
      person: data.person,
      safeFoods: data.safeFoods,
      foodsData: data.foodsData,
    );
  }
}

final pdfReportProvider =
    AsyncNotifierProvider.family<PdfReportNotifier, PdfReportViewData, String>(
      PdfReportNotifier.new,
    );
