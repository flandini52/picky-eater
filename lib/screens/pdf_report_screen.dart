import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/exposure_level.dart';
import '../database/app_database.dart';
import '../models/person_entity.dart';
import '../providers/pdf_report_provider.dart';

class PdfReportScreen extends ConsumerStatefulWidget {
  final PersonEntity person;

  const PdfReportScreen({super.key, required this.person});

  @override
  ConsumerState<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends ConsumerState<PdfReportScreen> {
  bool _generating = false;
  File? _generatedFile;

  Future<void> _generatePdf() async {
    setState(() => _generating = true);
    try {
      final notifier = ref.read(pdfReportProvider(widget.person.id).notifier);
      final file = await notifier.generatePdf();
      if (mounted) {
        setState(() => _generatedFile = file);
        await _showGeneratedDialog(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella generazione del PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _showGeneratedDialog(File file) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green.shade600),
        title: const Text('PDF generato con successo'),
        content: Text(
          'Salvato in:\n${file.path}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _shareFile();
            },
            child: const Text('Condividi ora'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile() async {
    final file = _generatedFile;
    if (file == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Report progressi di ${widget.person.name}',
          text:
              'Report progressi alimentari di ${widget.person.name} — Picky Eater',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella condivisione: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(pdfReportProvider(widget.person.id));

    return Scaffold(
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (data) => _buildContent(data),
      ),
    );
  }

  Widget _buildContent(PdfReportViewData data) {
    final totalSessions = data.foodsData.fold<int>(
      0,
      (sum, d) => sum + d.sessions.length,
    );
    final isEmpty = data.foodsData.isEmpty && data.safeFoods.isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.crema,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report progressi di ${data.person.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.safeFoods.length} safe foods · ${data.foodsData.length} alimenti in percorso · $totalSessions sessioni',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Nessun alimento da includere nel report.'),
                  ),
                )
              else ...[
                if (data.safeFoods.isNotEmpty) ...[
                  Text(
                    'Safe foods (${data.safeFoods.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.safeFoods
                        .map(
                          (food) => Chip(
                            label: Text(food.name),
                            avatar: Text(food.category.emoji),
                            backgroundColor: Colors.green.shade50,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (data.foodsData.isNotEmpty) ...[
                  const Text(
                    'Alimenti in percorso',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...data.foodsData.map(
                    (foodData) => _FoodPreviewTile(data: foodData),
                  ),
                ],
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_generating || isEmpty) ? null : _generatePdf,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    _generating ? 'Generazione in corso...' : 'Genera PDF',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.corallo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _generatedFile == null ? null : _shareFile,
                  icon: const Icon(Icons.share),
                  label: const Text('Condividi PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodPreviewTile extends StatelessWidget {
  final FoodReportData data;

  const _FoodPreviewTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final level = ExposureLevel.values[data.food.currentLevel];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(data.food.name),
        subtitle: Text('${data.food.category} · ${level.label}'),
        trailing: Text(
          '${data.sessions.length} sessioni',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
