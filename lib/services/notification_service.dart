import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _channelId = 'inactivity_reminders';
  static const _channelName = 'Promemoria inattività';
  static const _channelDescription =
      'Promemoria per sessioni non pianificate da tempo';
  static const _keyScheduledPersonIds = 'notification_scheduled_person_ids';
  static const _keyDuePrefix = 'notification_due_';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _timezoneInitialized = false;

  void _ensureTimezoneInitialized() {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.abs().inHours;
    final locationName = hours == 0
        ? 'UTC'
        : 'Etc/GMT${offset.isNegative ? '+' : '-'}$hours';
    tz.setLocalLocation(tz.getLocation(locationName));
    _timezoneInitialized = true;
  }

  /// Inizializza il plugin. Mostra il popup nativo permessi al primo avvio.
  /// Restituisce true se i permessi sono stati concessi.
  Future<bool> initialize() async {
    _ensureTimezoneInitialized();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: initSettings);

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Schedula la notifica di inattività per una persona.
  /// [personId] genera l'ID notifica univoco via hashCode.
  /// [personName] usato nel testo della notifica.
  /// [dueDate] quando deve scattare.
  /// [thresholdDays] soglia configurata, usata nel testo della notifica.
  Future<void> scheduleInactivityNotification({
    required String personId,
    required String personName,
    required DateTime dueDate,
    required int thresholdDays,
  }) async {
    _ensureTimezoneInitialized();

    final id = personId.hashCode;
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Il sistema operativo può revocare il permesso di allarmi esatti (o le
    // notifiche in generale) in qualsiasi momento dalle sue impostazioni:
    // in quel caso il plugin lancia un'eccezione a runtime. La ingoiamo qui
    // così un permesso revocato non fa crashare il flusso di chi chiama
    // (es. il completamento di una sessione).
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Picky Eater',
        body:
            'Sono passati $thresholdDays giorni dall\'ultima sessione di '
            '$personName. Vuoi pianificarne una?',
        scheduledDate: tz.TZDateTime.from(dueDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      await _saveScheduledDate(personId, dueDate);
    } catch (_) {
      await _removeScheduledDate(personId);
    }
  }

  /// Cancella la notifica di una persona specifica.
  Future<void> cancelNotification(String personId) async {
    try {
      await _plugin.cancel(id: personId.hashCode);
    } catch (_) {
      // Nessuna notifica pendente o plugin non disponibile: nulla da fare.
    }
    await _removeScheduledDate(personId);
  }

  /// Cancella tutte le notifiche (quando si disattivano globalmente).
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Nessuna notifica pendente o plugin non disponibile: nulla da fare.
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_keyScheduledPersonIds) ?? [];
    for (final personId in ids) {
      await prefs.remove('$_keyDuePrefix$personId');
    }
    await prefs.remove(_keyScheduledPersonIds);
  }

  /// Restituisce la data programmata per la notifica di una persona.
  /// Usato nello screen impostazioni per mostrare "Prossimo promemoria: tra X giorni".
  Future<DateTime?> getScheduledDate(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString('$_keyDuePrefix$personId');
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Apre le impostazioni di sistema dell'app (per quando il permesso è negato).
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  Future<void> _saveScheduledDate(String personId, DateTime dueDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyDuePrefix$personId', dueDate.toIso8601String());
    final ids = prefs.getStringList(_keyScheduledPersonIds) ?? [];
    if (!ids.contains(personId)) {
      await prefs.setStringList(_keyScheduledPersonIds, [...ids, personId]);
    }
  }

  Future<void> _removeScheduledDate(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyDuePrefix$personId');
    final ids = prefs.getStringList(_keyScheduledPersonIds) ?? [];
    ids.remove(personId);
    await prefs.setStringList(_keyScheduledPersonIds, ids);
  }
}
