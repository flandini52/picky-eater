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
│   ├── session_outcome.dart     # SessionOutcome + extension (legacy)
│   └── food_category_color.dart # foodCategoryColors + extension .categoryColor su String
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

### Safe foods

Un alimento può essere marcato `isSafeFood` (`foods.isSafeFood`, `FoodEntity.isSafeFood`, default `false`) per indicare che il bambino lo mangia già senza difficoltà — non è più "in percorso SOS".

- **`FoodRepository`**: `getSosFoodsByPerson` (solo `isSafeFood == false`), `getSafeFoodsByPerson` (solo `isSafeFood == true`), `setSafeFood(foodId, bool)`. `getFoodsByPerson` resta invariato e restituisce **tutti** gli alimenti (safe + SOS) — usato dove serve la lista completa.
- **`food_list_screen.dart`**: due sezioni, "Alimenti in percorso" (SOS) e "Safe foods". Le card safe food mostrano un badge verde "✓ Safe" invece di barra progresso/livello, e il menu a tre puntini offre "Rimuovi da safe foods" invece di "Imposta livello".
- **`add_food_screen.dart`**: toggle "È un safe food?" — se attivo nasconde il selettore livello e usa `ExposureLevel.eats` come livello di default.
- **`calendar_screen.dart`**: il dropdown di `AddSessionSheet` mostra solo alimenti SOS — filtrato al punto di passaggio verso la sheet, **non** nel provider generale (altrimenti si romperebbe il lookup nome-alimento delle sessioni esistenti collegate ad alimenti diventati safe food nel frattempo).
- **Report PDF**: sezione dedicata "Safe foods" (lista nome + categoria) prima della sezione progressi, che include solo gli alimenti SOS.

---

## Database — schema attuale (schemaVersion: 7)

```
families       → id, name
persons        → id, familyId, name, birthDate, avatarColor, createdAt
foods          → id, personId, name, category, currentLevel, isSafeFood
sessions       → id, personId, foodId, date, targetLevel, activity,
                 achievedLevel, achievedActivity, outcome(legacy), notes
weeklyGoals    → personId, targetSessions
badges         → id, personId, badgeType, unlockedAt
```

`persons.createdAt` è `DateTime?` **nullable, senza default a livello di colonna** (`dateTime().nullable()()`). SQLite non supporta `ALTER TABLE ... ADD COLUMN` con un default non costante (es. `currentDateAndTime`) — usarlo fa fallire la migrazione a runtime con `SqliteException(1): Cannot add a column with non-constant default`. Il valore viene impostato lato Dart in `PersonRepository.insertPerson` (`createdAt: Value(DateTime.now())`), non nello schema. Chi consuma il campo (es. `NotificationNotifier.rescheduleAll`) deve gestire l'eventuale `null` con un fallback esplicito.

### Migrazioni applicate

- v1 → schema iniziale
- v2 → aggiunto `sessions.activity`
- v3 → create tabelle `weeklyGoals` e `badges`
- v4 → aggiunto `sessions.outcome` (legacy, non più scritto attivamente)
- v5 → aggiunto `sessions.achievedActivity`
- v6 → aggiunto `foods.isSafeFood` (default `false`)
- v7 → aggiunto `persons.createdAt` (nullable, nessun default — vedi nota sopra)

**Dopo qualsiasi modifica allo schema**: incrementa `schemaVersion`, aggiungi la migrazione in `onUpgrade`, poi lancia `dart run build_runner build`. **Mai usare un default non costante** (es. `currentDateAndTime`, `DateTime.now()`) in una colonna aggiunta via `addColumn`: SQLite lo rifiuta a runtime. Se serve un timestamp di creazione, rendere la colonna nullable e impostarlo lato Dart nel repository all'insert.

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
5. `flutter test` (11 test: 4 FoodRepository + 3 SessionRepository + 3 PdfReportService + 1 placeholder)
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
- ✅ Safe foods — marcare un alimento come "già mangiato senza difficoltà", escluso dal percorso SOS e dal calendario (vedi sezione Safe foods sopra)
- ✅ Report PDF progressi — genera e condivide (WhatsApp/email/Telegram) un PDF con safe foods, alimenti in percorso e riepilogo (`lib/services/pdf_report_service.dart`, `pdf_report_provider.dart`, `pdf_report_screen.dart`, 4ª tab "Report" in `home_screen.dart`)
- ✅ Redesign palette Salvia/Pesca/Crema/Corallo su tutte le schermate (non verificato visivamente su device)
- ✅ Notifiche locali di inattività per persona, soglia configurabile, schermata dedicata raggiungibile da Impostazioni (vedi sezione "Notifiche locali" sotto)

---

## Da fare

### Debito tecnico residuo

- [ ] **Punto 4 refactoring** — riorganizzazione feature-first (`lib/features/food/`, `calendar/`, `dashboard/`, `achievements/`) — bassa priorità, la logica è già separata dalla UI
- [ ] Espandere i test: `PersonRepository`, `BadgeRepository`, `NotificationSettingsRepository`
- [ ] `lib/services/` è vuota — rimuovere o popolare quando si aggiungono notifiche/export

### Decisione presa: PDF via share sheet, non QR

Il flusso "QR code → professionista scansiona → scarica PDF" è stato **scartato**: un QR code contiene al massimo ~2-3 KB, un PDF con report di sessioni pesa molto di più — il QR non può trasportare il file stesso, servirebbe comunque un canale di trasferimento vero sotto (server/rete), che rompe il vincolo local-first.

**Soluzione adottata**: nuova schermata (tab in basso a destra nella navigazione) con bottone "Genera PDF". Il genitore genera il PDF localmente, poi lo condivide tramite lo share sheet nativo di iOS/Android (pacchetto `share_plus`) — WhatsApp, email, Telegram, o qualunque app scelga l'utente. Resta 100% local-first, il file non passa mai da un server nostro.

**Fatto**: implementato su 5 file — `lib/services/pdf_report_service.dart` (`PdfReportService` + `FoodReportData`, zero dipendenze Flutter/Riverpod, genera il PDF con pacchetto `pdf`: header, sezione "Safe foods" (nome + categoria), tabella sessioni per alimento SOS con colonna "Esito" colorata verde/ambra/blu coerente con `OutcomeBadge`, riepilogo generale con conteggio safe foods, footer con numero pagina — salvato in `getApplicationDocumentsDirectory()`, non nella cache temporanea: persistente tra un tap e l'altro dei due bottoni separati e non cancellato in automatico dal sistema), `lib/providers/pdf_report_provider.dart` (`PdfReportNotifier`, family su `personId`, carica safe foods e alimenti SOS separatamente via `getSafeFoodsByPerson`/`getSosFoodsByPerson`, raggruppa sessioni per alimento, espone `generatePdf()`), `lib/screens/pdf_report_screen.dart` (nessuna AppBar, coerente con le altre 3 tab — anteprima con sezione safe foods a chip + lista alimenti in percorso, **due bottoni separati**: "Genera PDF" — Corallo, crea il file e apre un `AlertDialog` di conferma con percorso del file e bottoni "Condividi ora"/"Chiudi" — e "Condividi PDF" — OutlinedButton, disabilitato finché non è stato generato un file, usa `SharePlus.instance.share(ShareParams(...))` — l'API moderna del pacchetto v13, `Share.shareXFiles` è deprecato), 4° tab "Report" in `home_screen.dart` (`BottomNavigationBarType.fixed` esplicito, necessario oltre i 3 item). Pacchetti aggiunti: `pdf`, `share_plus`, `path_provider` (+ `path_provider_platform_interface` come dev dependency per mockare `getApplicationDocumentsPath` nei test). Nota tecnica: il carattere `—` (em dash) non è renderizzabile dal font base Helvetica del pacchetto `pdf` — usare `-` per i placeholder. Verificato con `flutter analyze`/`format`/`test` (11/11, incluso un test che valida la firma `%PDF-` del file generato e uno per il caso "solo safe foods, zero alimenti SOS") e build APK reale — non verificato visivamente (nessun tool screenshot in sessione).

Il professionista **non ha un proprio account o vista nell'app** — riceve solo il PDF condiviso dal genitore. L'esperienza app oggi è single-sided (solo famiglia); un'eventuale vista professionista resta fuori scope per ora.

Il QR resta un'idea valida ma **per un uso diverso**: eventuale futuro onboarding/referral professionista (il professionista genera un QR/link con un ID corto per collegare il proprio account al genitore ai fini della commissione referral) — non è collegato al trasferimento del PDF.

### Design system — palette definita

```
Salvia   #7BA88C  — primario: navigazione, pulsanti principali. Calma, non clinico.
Pesca    #F0997B  — secondario: illustrazioni, elementi decorativi legati al cibo.
Crema    #FBF7EE  — sfondo principale delle schermate (più caldo del bianco puro).
Corallo  #D85A30  — accento CTA e badge premio, usare con parsimonia (colore più acceso).
Neutri   —         testo, sfondi secondari, card, divisori.
```

**Accenti di stato** (esito sessione, riusano il pattern outcome_badge già esistente):
```
Verde        — livello completato / successo
Ambra        — in corso
Blu          — informazione neutra
Rosso tenue  — solo errori reali (MAI per "cibo difficile", che non è un errore)
```

Stile pastello confermato. Redesign da applicare **ovunque** nell'app (non solo dashboard), un'unica esperienza per ora (famiglia); nessuna variante palette per professionista, dato che il professionista non ha accesso diretto all'app.

**Stato redesign**: completo su tutte le schermate, vedi `lib/core/app_theme.dart` (`AppColors`, `buildAppTheme()`, usato in `main.dart`). Aggiornate: `home_screen.dart`, `dashboard_screen.dart`, `food_list_screen.dart`, `calendar_screen.dart`, `food_detail_screen.dart`, `achivements_screen.dart`, `add_food_screen.dart`, `edit_food_screen.dart`, `edit_person_screen.dart`, `add_session_sheet.dart`, `complete_session_sheet.dart`, `activity_selector.dart` (widget condiviso). Zero `Colors.orange` rimasti per il brand chrome. La scala arcobaleno a 6 colori di `_levelColor()` (in `dashboard_screen.dart`, `food_list_screen.dart`, `food_detail_screen.dart`) è stata **lasciata invariata di proposito** (concetto separato dalla palette di brand, non specificato nel redesign). Il verde/rosso di stato in `achivements_screen.dart` (badge sbloccato/check) e i pulsanti rossi "Elimina" (destructive action) sono stati **lasciati invariati** perché già semanticamente corretti secondo gli accenti di stato definiti sopra.

**Decisione presa: niente AppBar per le 3 tab (Progressi/Alimenti/Calendario)**. `DashboardScreen`, `FoodListScreen`, `CalendarScreen` avevano ciascuna una propria `AppBar` (title "Progressi di X"/"Alimenti di X"/"Calendario") impilata **sotto** l'header di `home_screen.dart` (che mostra già nome persona + impostazioni) — due blocchi ridondanti, uno dei quali duplicava il nome persona. Prima tentativo: ridurre `AppBarTheme.toolbarHeight` (56→48→24) — scartato perché a 24dp il testo si rompeva visivamente (andava in basso nel blocco). **Soluzione adottata**: rimossa del tutto la `AppBar` dalle 3 schermate tab (restano `Scaffold` senza `appBar:`); il pulsante "traguardi" (prima action della AppBar di `DashboardScreen`) è stato spostato nell'header di `home_screen.dart`, visibile solo quando la tab attiva è "Progressi". Il testo del titolo non è stato sostituito con altro: la label della tab nel bottom nav ("Progressi"/"Alimenti"/"Calendario") è già sufficiente. `AppBarTheme.toolbarHeight` **rimossa** (torna al default 56) perché le rimanenti schermate con AppBar (dettaglio alimento, traguardi, add/edit alimento/persona) sono route push a schermo intero, non impilate sotto l'header di `home_screen.dart`, quindi non hanno il problema del doppio blocco.

Nessuna verifica visiva fatta (nessun tool screenshot disponibile in sessione) — solo `flutter analyze`/`format`/`test`/`build apk --debug` verdi. Da controllare su device prima di considerare la modifica conclusa.

### Colori per alimento — fatto: `lib/core/food_category_color.dart`

Mappa `foodCategoryColors` + extension `.categoryColor` su `String`, 7 tonalità pastello (rosa cipria, verde salvia chiaro, terracotta chiaro, azzurro polvere, sabbia, lavanda, malva) più un neutro di fallback. File isolato, non ancora cablato nelle schermate — l'integrazione visiva (calendario, lista alimenti, food detail) è parte del redesign (fase 3), non di questo step.

### Colori per alimento — decisione: per macro-categoria, non per singolo alimento

Motivazione: la tabella `foods` ha già un campo `category`, quindi zero migrazione di schema — si tratta solo di una `const Map<String, Color>` (o enum categoria→colore) in `lib/core/`. Usare colori per-alimento avrebbe richiesto o troppi colori (rischio di uscire dal tono pastello) o colori ripetuti tra alimenti diversi, vanificando lo scopo.

Il colore-categoria va usato in modo consistente in tutta l'app (calendario, lista alimenti, food detail) ma **deve restare visivamente distinto dagli accenti di stato** (verde/ambra/blu/rosso sopra) per non generare ambiguità tra "categoria alimento" e "esito sessione". Serve una sotto-palette pastello dedicata alle categorie (es. lavanda, sabbia, azzurro polvere, terracotta chiaro), in armonia con Salvia/Pesca/Crema/Corallo ma fuori dal set semaforico. Il colore è un aiuto visivo di raggruppamento, non sostituisce il nome alimento in etichetta.

### Notifiche locali — fatto (promemoria di inattività, non promemoria sessione pianificata)

**Nota**: il trigger inizialmente previsto qui ("promemoria alla data/ora di una sessione pianificata in `AddSessionSheet`") è stato **sostituito** da un trigger diverso durante l'implementazione: un promemoria di **inattività**. Nessuna sessione pianificata viene notificata a una data specifica; il sistema invece notifica quando passano troppi giorni senza una sessione *completata*.

**Comportamento**: soglia giorni configurabile globalmente (default 7, min 1, max 30, `NotificationSettingsRepository`, `shared_preferences`). Ogni persona ha una notifica indipendente schedulata con ID univoco `personId.hashCode`. La notifica scatta se `DateTime.now() - ultimaSessioneCompletata > sogliaGiorni`; se la persona non ha ancora sessioni completate, si usa `persons.createdAt` come base (vedi nota sullo schema sopra — nullable, fallback a `DateTime.now()` se anche quello manca). Al completamento di una sessione (`CalendarNotifier.completeSession`), solo la notifica della persona coinvolta viene cancellata e rischedulata — le altre persone non vengono toccate.

File coinvolti:
- `lib/services/notification_service.dart` — `NotificationService`, singleton, zero dipendenze Riverpod/Drift. Wrappa `flutter_local_notifications` (schedulazione via `zonedSchedule`, timezone calcolata a offset fisso dal device senza dipendenze aggiuntive) + `permission_handler` (richiesta permesso). Persiste le date schedulate per persona su `shared_preferences` (il plugin non le espone tramite `pendingNotificationRequests`). `scheduleInactivityNotification`/`cancelNotification`/`cancelAll` sono avvolte in try/catch: se il permesso viene revocato dalle impostazioni di sistema dopo l'attivazione, il plugin lancia un'eccezione runtime che qui viene ingoiata per non far crashare chi chiama (es. il completamento di una sessione).
- `lib/repositories/notification_settings_repository.dart` — `NotificationSettingsRepository`, solo `shared_preferences`, non Drift: `isEnabled`/`setEnabled`, `getThresholdDays`/`setThresholdDays`.
- `lib/providers/notification_provider.dart` — `notificationProvider` (`AsyncNotifierProvider<NotificationNotifier, NotificationState>`), espone stato per persona (`PersonNotificationStatus`: ultima sessione, prossima notifica) e i metodi `requestPermissionAndEnable`, `setEnabled`, `setThresholdDays`, `rescheduleForPerson`, `rescheduleAll`.
- `lib/screens/notification_settings_screen.dart` — `NotificationSettingsScreen`, raggiungibile da "Notifiche" nel bottom sheet impostazioni di `home_screen.dart` (non più placeholder). Switch attiva/disattiva, stepper soglia giorni (visibile solo se attivo), sezione stato promemoria per persona, banner "Apri impostazioni telefono" se il permesso è negato.
- `lib/main.dart` — chiama `NotificationService().initialize()` prima di `runApp` per mostrare il popup permessi nativo al primo avvio (idempotente: l'OS non ri-mostra il dialog se già deciso).
- Android: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` in `AndroidManifest.xml` + 2 receiver di `flutter_local_notifications`. `android/app/build.gradle.kts` richiede `isCoreLibraryDesugaringEnabled = true` + dipendenza `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` — requisito documentato del plugin, senza il quale la build fallisce con "Dependency ':flutter_local_notifications' requires core library desugaring to be enabled".
- iOS: `UNUserNotificationCenter.current().delegate` impostato in `AppDelegate.swift`.

Verificato con `flutter analyze`/`format`/`test` (11/11) verdi e avvio reale su Pixel 7 (nessun crash, nessuna `SqliteException`, flusso completo testato: aggiunta persona → navigazione schermate → generazione PDF).

### Schermata statistiche — ripresa in roadmap

Punto rimasto in sospeso da tempo: separare "Progressi" (analytics vere: trend, confronti tra alimenti/periodi) da "Alimenti" (lista operativa, oggi mescolate in `food_list_screen.dart`/`dashboard_screen.dart`). Da riprendere e specificare come parte del redesign.

### Ordine di lavoro concordato (feature in corso)

1. **Fase 0 — Bundle ID + `android:allowBackup="false"`** — `allowBackup="false"` fatto. Bundle ID rimandato: verrà scelto come reverse-DNS di un dominio non ancora acquistato (oggi resta il placeholder `com.example.picky_eater` / `com.example.pickyEater`) — da fare prima della build di release, non blocca il lavoro attuale
2. ~~**Colori per macro-categoria**~~ — fatto, vedi `lib/core/food_category_color.dart`
3. ~~**Redesign completo**~~ — fatto su tutte le schermate, vedi sezione sopra (manca solo la verifica visiva su device)
4. ~~**PDF + share sheet**~~ — fatto, vedi sezione sopra. Nota: non include ancora il banner di sicurezza/privacy dati menzionato originariamente — da valutare se aggiungerlo
5. ~~**Notifiche locali**~~ — fatto, vedi sezione sopra (promemoria di inattività, non promemoria sessione pianificata come previsto originariamente)
6. **TestFlight beta** con la business partner
7. **Keystore release + store assets + monetizzazione** — ultimo miglio

### Funzionalità priorità alta (aggiornate)

- [x] **Colori per macro-categoria alimento** — `lib/core/food_category_color.dart`, non ancora cablato nella UI (parte del redesign)
- [x] **Redesign completo ovunque** — palette Salvia/Pesca/Crema/Corallo + neutri, stile pastello, un'unica esperienza (famiglia). Non verificato visivamente su device
- [ ] **Schermata statistiche/Progressi** — separare da "Alimenti", non ancora affrontato nonostante il redesign (era previsto "come parte del redesign" ma non è stato fatto)
- [x] **PDF report + share sheet** — fatto (vedi sopra). Manca ancora: banner di sicurezza/privacy dati nella schermata (era nella richiesta originale, non implementato)
- [x] **Notifiche locali** — fatto: promemoria di inattività per persona, soglia configurabile (vedi sezione sopra)
- [ ] **Obiettivo settimanale configurabile** — ora fisso a 3, deve essere modificabile dall'utente
- [ ] **Onboarding** — schermata introduttiva per nuovi utenti con spiegazione metodo SOS

### Funzionalità priorità media

- [ ] **Drag & drop** riordinamento alimenti nella lista
- [ ] **QR onboarding/referral professionista** — riuso dell'idea QR originale, per collegare account professionista-famiglia ai fini commissione referral (non per il PDF)

### Prima del lancio

- [ ] App icon e splash screen (coordinati con il redesign)
- [ ] Nome app definitivo (ora "Picky Eater")
- [ ] Bundle ID definitivo — rimandato: sarà il reverse-DNS di un dominio non ancora acquistato, va fatto prima della build di release
- [x] `android:allowBackup="false"` — impostato in `android/app/src/main/AndroidManifest.xml`
- [ ] Keystore di release proprio — oggi il build di release usa ancora la firma di debug, Google Play non lo accetterebbe
- [ ] Privacy policy (obbligatoria per App Store — tratta dati di minori)
- [ ] Build release firmata per Google Play (`flutter build appbundle --release`)
- [ ] Xcode setup completo per TestFlight/App Store
- [ ] Aggiungere `flutter build apk --release` al CI
- [ ] Valutare cifratura del database (SQLCipher) prima del lancio pubblico — dati potenzialmente sanitari di minori, oggi non cifrati at-rest

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