# Picky Eater — Contesto per Claude Code

## Cos'è questa app

App Flutter mobile per famiglie che seguono il metodo **SOS (Sequential Oral Sensory)** di Kay Toomey per la terapia di esposizione alimentare con bambini (o adulti) picky eaters. Permette di tracciare i progressi di esposizione agli alimenti su una scala strutturata a 6 livelli con 3 attività specifiche per livello (18 step granulari totali), pianificare sessioni sul calendario, e visualizzare i progressi nel tempo.

**Obiettivo finale**: app production-ready per distribuzione su App Store (iOS) e Google Play (Android), con un modello di business basato su trial gratuito di 2 settimane e referral di professionisti (dietiste, logopediste).

**Vincolo fondamentale**: local-first, nessun backend, nessuna sincronizzazione cloud. I dati sensibili di minori non escono dal dispositivo (GDPR). La sync remota con Supabase è in roadmap ma non implementata.

---

## Stack tecnico

- **Flutter** 3.44.4, Dart 3.12.2, Material 3
- **Drift** (SQLite locale) — ORM per la persistenza, con codice generato da `build_runner`
- **flutter_riverpod** — state management con `AsyncNotifierProvider.family`
- **fl_chart** — grafici andamento progressi
- **table_calendar** — calendario sessioni
- **Sviluppo**: Mac, test su Pixel 7 Android (API 36)
- **CI**: GitHub Actions (`.github/workflows/flutter.yml`) — analyze + test su push/PR su main

---

## Architettura

### Layer (dalla UI verso il basso)

```
Screens / Widgets / Sheets
        ↓
    Providers (Riverpod)
        ↓
    Repositories
        ↓
    AppDatabase (Drift)
        ↓
      SQLite
```

### Struttura cartelle

```
lib/
├── main.dart                    # ProviderScope con databaseProvider override
├── core/                        # Enum e costanti di dominio puri, zero dipendenze Drift
│   ├── exposure_level.dart      # ExposureLevel + extension + levelActivities + granularIndex*
│   ├── badge_type.dart          # BadgeType + extension
│   └── session_outcome.dart     # SessionOutcome + extension (legacy)
├── database/
│   ├── app_database.dart        # Tabelle Drift + query
│   └── app_database.g.dart      # GENERATO — non editare manualmente
├── models/                      # Entità di dominio pure (zero dipendenze Drift/Flutter)
│   ├── food_entity.dart
│   ├── session_entity.dart
│   ├── person_entity.dart
│   ├── family_entity.dart
│   └── badge_entity.dart
├── repositories/                # Mapper Drift→dominio, unico punto di accesso al DB
│   ├── food_repository.dart
│   ├── session_repository.dart
│   ├── person_repository.dart
│   ├── family_repository.dart
│   ├── badge_repository.dart
│   └── weekly_goal_repository.dart
├── providers/                   # Riverpod providers e AsyncNotifier
│   ├── database_provider.dart   # Provider<AppDatabase> — iniettato via ProviderScope
│   ├── dashboard_provider.dart  # foodRepositoryProvider, sessionRepositoryProvider, DashboardNotifier
│   ├── calendar_provider.dart   # calendarProvider, CalendarNotifier, badgeRepositoryProvider
│   └── person_provider.dart     # familyProvider, FamilyNotifier, personRepositoryProvider
├── screens/
│   ├── home_screen.dart         # ConsumerStatefulWidget — nav, selettore persona, settings
│   ├── dashboard_screen.dart    # ConsumerWidget — progressi alimenti + obiettivo settimanale
│   ├── food_list_screen.dart    # ConsumerStatefulWidget — lista alimenti compatta, alfabetica
│   ├── food_detail_screen.dart  # ConsumerWidget — accetta FoodEntity, grafico + storico
│   ├── calendar_screen.dart     # ConsumerWidget — calendario + lista sessioni giorno
│   ├── achivements_screen.dart  # ConsumerWidget — badge sbloccati/bloccati
│   ├── add_food_screen.dart     # StatefulWidget — form nuovo alimento → ritorna FoodEntity
│   ├── edit_food_screen.dart    # ConsumerStatefulWidget — modifica/elimina alimento
│   └── edit_person_screen.dart  # ConsumerStatefulWidget — modifica/elimina persona
├── sheets/                      # Bottom sheet estratti da calendar_screen
│   ├── add_session_sheet.dart   # ConsumerStatefulWidget — pianifica sessione
│   └── complete_session_sheet.dart # ConsumerStatefulWidget — registra risultato sessione
└── widgets/                     # Widget riutilizzabili
    ├── outcome_badge.dart        # Badge colorato esito sessione (calcolato automaticamente)
    └── activity_selector.dart   # Lista attività SOS selezionabili

test/
├── repositories/
│   └── food_repository_test.dart  # 3 test: insert+get, updateFoodLevel, deleteFood cascata
└── widget_test.dart               # placeholder
```

---

## Dominio — il metodo SOS

### I 6 livelli di esposizione (ExposureLevel) — in `lib/core/exposure_level.dart`

```dart
enum ExposureLevel {
  tolerates,    // 🔴 Tollera — è nella stessa stanza con il cibo
  interacts,    // 🟠 Interagisce — usa utensili, tocca con strumenti
  smells,       // 🟡 Annusa — si avvicina e annusa
  touches,      // 🟢 Tocca — tocca con dita, mano, viso
  tastes,       // 🔵 Assaggia — labbra, punta della lingua
  eats,         // ⭐ Mangia — mastica e deglutisce
}
```

### Le 3 attività per livello (levelActivities) — in `lib/core/exposure_level.dart`

Ogni livello ha 3 attività specifiche (18 step granulari totali, indice 0-17).
L'indice granulare si calcola: `livello.index * 3 + posizione_in_lista`.
Usato nell'asse Y del grafico in `food_detail_screen.dart`.

### Flusso sessione

1. **Pianifica** (AddSessionSheet): scegli alimento + livello obiettivo + attività suggerita
2. **Registra** (CompleteSessionSheet): scegli livello più alto raggiunto + attività completata + note opzionali
3. **Esito automatico**: confronto `achievedLevel` vs `targetLevel` → badge discreto (verde/ambra/blu)
4. Se `achievedLevel > food.currentLevel` → aggiorna automaticamente il livello attuale dell'alimento
5. Controlla e sblocca eventuali badge (BadgeType)

---

## Database — schema attuale (schemaVersion: 5)

```
families       → id, name
persons        → id, familyId, name, birthDate, avatarColor
foods          → id, personId, name, category, currentLevel
sessions       → id, personId, foodId, date, targetLevel, activity,
                 achievedLevel, achievedActivity, outcome(legacy), notes
weeklyGoals    → personId, targetSessions
badges         → id, personId, badgeType, unlockedAt
```

### Migrazioni applicate

- v1 → schema iniziale
- v2 → aggiunto `sessions.activity`
- v3 → create tabelle `weeklyGoals` e `badges`
- v4 → aggiunto `sessions.outcome` (legacy, non più scritto attivamente)
- v5 → aggiunto `sessions.achievedActivity`

**Dopo qualsiasi modifica allo schema**: incrementa `schemaVersion`, aggiungi la migrazione in `onUpgrade`, poi lancia `dart run build_runner build`.

### Costruttori di AppDatabase

```dart
// Produzione — usato in main.dart via databaseProvider
AppDatabase()

// Test — costruttore dedicato, mai usare in produzione
AppDatabase.forTesting(QueryExecutor executor)
```

Il costruttore `forTesting` rende esplicita l'intenzione e impedisce usi accidentali in produzione.

---

## Convenzioni di codice

### Provider pattern

```dart
// Repository provider — legge sempre da databaseProvider
final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(ref.watch(databaseProvider));
});

// AsyncNotifier con family — personId come parametro
class DashboardNotifier extends FamilyAsyncNotifier<DashboardData, String> {
  @override
  Future<DashboardData> build(String personId) async { ... }
}
final dashboardProvider = AsyncNotifierProvider.family<...>(DashboardNotifier.new);

// Uso nelle screen
final data = ref.watch(dashboardProvider(person.id));
```

### Regola fondamentale

- Le **screen** non importano mai `AppDatabase` direttamente per fare query
- Le **screen** non importano mai `main.dart`
- Le **screen** leggono solo da **provider** Riverpod
- I **provider** leggono solo da **repository**
- I **repository** sono gli unici a parlare con `AppDatabase`
- I **modelli** (`*Entity`) sono classi Dart pure, zero dipendenze da Drift o Flutter
- Gli **enum di dominio** (`ExposureLevel`, `BadgeType`, ecc.) stanno in `lib/core/`, non in `app_database.dart`

### Testabilità

Il database è iniettabile via Riverpod usando il costruttore dedicato:

```dart
// In ogni test — database in-memory, zero SQLite reale, zero side effect
setUp(() {
  db = AppDatabase.forTesting(NativeDatabase.memory());
  container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
    ],
  );
});

tearDown(() async {
  await db.close();
  container.dispose();
});

// Uso nei test
final repo = container.read(foodRepositoryProvider);
```

Vedi `test/repositories/food_repository_test.dart` come riferimento.

---

## CI/CD

File: `.github/workflows/flutter.yml`

Steps su ogni push/PR su `main`:
1. `flutter pub get`
2. `dart run build_runner build` (rigenera codice Drift — `app_database.g.dart` non è in repo)
3. `dart format --output=none --set-exit-if-changed .` (zero file da riformattare)
4. `flutter analyze` (zero errori attesi)
5. `flutter test` (7 test: 3 FoodRepository + 3 SessionRepository + 1 placeholder)
6. `flutter build apk --debug` (verifica che l'APK si generi davvero, non solo che compili)

**`app_database.g.dart` non è in repo** — viene rigenerato dal CI. Se aggiungi tabelle o query, ricordati di lanciare `dart run build_runner build` localmente prima di pushare.

---

## Funzionalità implementate

- ✅ Gestione multi-persona (profili famiglia indipendenti)
- ✅ Lista alimenti per persona (ordine alfabetico, card compatte)
- ✅ 6 livelli SOS con 3 attività specifiche per livello
- ✅ Calendario sessioni (pianificazione + registrazione)
- ✅ Aggiornamento automatico livello alimento dopo sessione
- ✅ Grafico andamento nel tempo (asse Y granulare 0-17)
- ✅ Storico sessioni per alimento
- ✅ Dashboard progressi con obiettivo settimanale
- ✅ Sistema badge/traguardi (6 badge) con popup sblocco
- ✅ Schermata traguardi con badge sbloccati/bloccati
- ✅ Modifica e cancellazione alimenti e persone (con cascata)
- ✅ Impostazioni (placeholder lingua e notifiche)

---

## Da fare

### Debito tecnico residuo

- [ ] **Punto 4 refactoring** — riorganizzazione feature-first (`lib/features/food/`, `calendar/`, `dashboard/`, `achievements/`) — bassa priorità, la logica è già separata dalla UI
- [ ] Espandere i test: `PersonRepository`, `BadgeRepository`
- [ ] `lib/services/` è vuota — rimuovere o popolare quando si aggiungono notifiche/export

### Funzionalità priorità alta

- [ ] **QR code + PDF report** — genitore genera QR, professionista scansiona e scarica PDF progressi (feature differenziante, alta priorità commerciale)
- [ ] **Notifiche locali** — promemoria sessioni pianificate
- [ ] **Obiettivo settimanale configurabile** — ora fisso a 3, deve essere modificabile dall'utente
- [ ] **Onboarding** — schermata introduttiva per nuovi utenti con spiegazione metodo SOS

### Funzionalità priorità media

- [ ] **Analytics dashboard** — separare "Progressi" (analytics veri: trend, confronti) da "Alimenti" (lista operativa)
- [ ] **Drag & drop** riordinamento alimenti nella lista

### Prima del lancio

- [ ] App icon e splash screen
- [ ] Nome app definitivo (ora "Picky Eater")
- [ ] Bundle ID (`com.tuonome.pickyeater`)
- [ ] Privacy policy (obbligatoria per App Store — tratta dati di minori)
- [ ] Build release firmata per Google Play (`flutter build appbundle --release`)
- [ ] Xcode setup completo per TestFlight/App Store
- [ ] Aggiungere `flutter build apk --release` al CI

---

## Note importanti per Claude Code

1. **Non usare mai `database` come variabile globale** — è stato rimosso. Usa sempre `ref.watch(databaseProvider)` o `ref.read(databaseProvider)` dentro un provider/notifier.

2. **Dopo modifiche al schema Drift** — sempre `dart run build_runner build` prima di `flutter analyze`.

3. **Il file `app_database.g.dart` non va editato** — è generato automaticamente.

4. **`flutter analyze` deve dare zero errori** prima di qualsiasi commit — il CI fallisce altrimenti.

5. **Costruttore `AppDatabase.forTesting`** — usarlo esclusivamente nei test. In produzione il database viene sempre creato in `main.dart` via `databaseProvider`.

6. **Enum di dominio** — `ExposureLevel`, `BadgeType`, `SessionOutcome` stanno in `lib/core/`, non in `app_database.dart`. Importa da lì.

7. **Convenzione nomi file**: `achivements_screen.dart` ha un typo (manca una 'e') — mantenere per consistenza con import esistenti finché non si fa un refactor dedicato.

8. **La repo è pubblica** su GitHub (`flandini52/picky-eater`) — nessuna chiave API o dato sensibile nel codice.

9. **Target primario**: Android (Pixel 7 per il testing), iOS in roadmap.
