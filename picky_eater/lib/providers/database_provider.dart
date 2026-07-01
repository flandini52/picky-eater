import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Provider dell'istanza AppDatabase.
/// Viene sovrascritto in main.dart con l'istanza reale,
/// e nei test con un database in-memory.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider deve essere sovrascritto in ProviderScope. '
    'Assicurati che main.dart passi overrides: [databaseProvider.overrideWithValue(db)]',
  );
});