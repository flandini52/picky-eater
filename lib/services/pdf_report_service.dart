import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/exposure_level.dart';
import '../models/food_entity.dart';
import '../models/person_entity.dart';
import '../models/session_entity.dart';

const _pdfSalvia = PdfColor.fromInt(0xFF7BA88C);
const _pdfCrema = PdfColor.fromInt(0xFFFBF7EE);
const _pdfTextSecondary = PdfColor.fromInt(0xFF7A756C);

/// Dati di un alimento e le sue sessioni, già pronti per il report.
/// Le sessioni includono sia quelle pianificate che quelle completate.
class FoodReportData {
  final FoodEntity food;
  final List<SessionEntity> sessions;

  const FoodReportData({required this.food, required this.sessions});
}

/// Genera il report PDF dei progressi di una persona.
/// Non dipende da Flutter né da Riverpod: riceve i dati già pronti
/// (caricati a monte dai repository) e restituisce un File.
class PdfReportService {
  Future<File> generateReport({
    required PersonEntity person,
    required List<FoodEntity> safeFoods,
    required List<FoodReportData> foodsData,
  }) async {
    final doc = pw.Document();
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader(person, generatedAt),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          if (safeFoods.isNotEmpty) ...[
            _buildSafeFoodsSection(safeFoods),
            pw.SizedBox(height: 16),
          ],
          ..._buildFoodSections(foodsData),
          pw.SizedBox(height: 12),
          _buildSummarySection(safeFoods, foodsData),
        ],
      ),
    );

    // Cartella documenti dell'app: privata ma persistente (non cancellata
    // automaticamente dal sistema come la cache temporanea).
    final dir = await getApplicationDocumentsDirectory();
    final safeName = person.name.replaceAll(RegExp(r'\s+'), '_');
    final fileName =
        'report_${safeName}_${_formatDateForFile(generatedAt)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  pw.Widget _buildHeader(PersonEntity person, DateTime generatedAt) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Picky Eater',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfSalvia,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Report progressi di ${person.name}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generato il ${_formatDate(generatedAt)}',
            style: const pw.TextStyle(fontSize: 9, color: _pdfTextSecondary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Pagina ${context.pageNumber} di ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  pw.Widget _buildSafeFoodsSection(List<FoodEntity> safeFoods) {
    final sorted = [...safeFoods]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Safe foods (${sorted.length})',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          sorted.map((f) => '${f.name} (${f.category})').join('  ·  '),
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  List<pw.Widget> _buildFoodSections(List<FoodReportData> foodsData) {
    final widgets = <pw.Widget>[];
    for (var i = 0; i < foodsData.length; i++) {
      widgets.add(_buildFoodSection(foodsData[i]));
      if (i < foodsData.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(pw.Divider(color: PdfColors.grey300));
        widgets.add(pw.SizedBox(height: 10));
      }
    }
    return widgets;
  }

  pw.Widget _buildFoodSection(FoodReportData data) {
    final food = data.food;
    final sessions = [...data.sessions]
      ..sort((a, b) => a.date.compareTo(b.date));
    final level = ExposureLevel.values[food.currentLevel];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          food.name,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${food.category} · Livello attuale: ${_plainLevelLabel(level)}',
          style: const pw.TextStyle(fontSize: 10, color: _pdfTextSecondary),
        ),
        pw.SizedBox(height: 8),
        if (sessions.isEmpty)
          pw.Text(
            'Nessuna sessione registrata.',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: _pdfTextSecondary,
            ),
          )
        else ...[
          _buildSessionsTable(sessions),
          pw.SizedBox(height: 6),
          pw.Text(
            '${sessions.length} sessioni totali · prima: ${_formatDate(sessions.first.date)} '
            '· ultima: ${_formatDate(sessions.last.date)}',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: _pdfTextSecondary,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSessionsTable(List<SessionEntity> sortedSessions) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Data',
        'Obiettivo',
        'Attività pianificata',
        'Raggiunto',
        'Attività completata',
        'Esito',
        'Note',
      ],
      data: sortedSessions.map((s) {
        final targetLabel = _plainLevelLabel(
          ExposureLevel.values[s.targetLevel],
        );
        final achievedLabel = s.achievedLevel != null
            ? _plainLevelLabel(ExposureLevel.values[s.achievedLevel!])
            : '-';
        final outcome = s.achievedLevel != null
            ? _outcomeText(s.targetLevel, s.achievedLevel!)
            : 'Pianificata';
        return [
          _formatDate(s.date),
          targetLabel,
          s.activity ?? '-',
          achievedLabel,
          s.achievedActivity ?? '-',
          outcome,
          s.notes ?? '',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _pdfSalvia),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      textStyleBuilder: (index, cell, rowNum) {
        // Colonna "Esito" (indice 5): colore in base all'esito della sessione.
        if (index != 5) return null;
        final session = sortedSessions[rowNum - 1];
        if (session.achievedLevel == null) {
          return const pw.TextStyle(fontSize: 8, color: PdfColors.grey600);
        }
        return pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _outcomeColor(session.targetLevel, session.achievedLevel!),
        );
      },
    );
  }

  pw.Widget _buildSummarySection(
    List<FoodEntity> safeFoods,
    List<FoodReportData> foodsData,
  ) {
    final totalSessions = foodsData.fold<int>(
      0,
      (sum, d) => sum + d.sessions.length,
    );
    final totalFoods = foodsData.length;

    final levelCounts = <ExposureLevel, int>{
      for (final l in ExposureLevel.values) l: 0,
    };
    for (final data in foodsData) {
      final level = ExposureLevel.values[data.food.currentLevel];
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _pdfCrema,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Riepilogo generale',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Safe foods: ${safeFoods.length}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Alimenti in percorso SOS: $totalFoods',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Sessioni registrate: $totalSessions',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Alimenti per livello:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          ...ExposureLevel.values.map(
            (l) => pw.Text(
              '${_plainLevelLabel(l)}: ${levelCounts[l]}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _outcomeText(int targetLevel, int achievedLevel) {
    if (achievedLevel > targetLevel) return 'Andato oltre l\'obiettivo';
    if (achievedLevel == targetLevel) return 'Obiettivo raggiunto';
    return 'Ci ha provato';
  }

  PdfColor _outcomeColor(int targetLevel, int achievedLevel) {
    if (achievedLevel > targetLevel) return PdfColors.blue700;
    if (achievedLevel == targetLevel) return PdfColors.green700;
    return PdfColors.amber800;
  }

  /// Etichetta del livello senza l'emoji (i font PDF base non la renderizzano).
  String _plainLevelLabel(ExposureLevel level) {
    return level.label.replaceFirst(RegExp(r'^\S+\s'), '');
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateForFile(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}
