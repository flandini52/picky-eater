import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/person_entity.dart';
import '../repositories/notification_settings_repository.dart';
import '../repositories/session_repository.dart';
import '../services/notification_service.dart';
import 'dashboard_provider.dart';
import 'person_provider.dart';

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
      return NotificationSettingsRepository();
    });

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class PersonNotificationStatus {
  final String personId;
  final String personName;
  final DateTime? lastSessionDate;
  final DateTime? nextNotificationDate;

  const PersonNotificationStatus({
    required this.personId,
    required this.personName,
    this.lastSessionDate,
    this.nextNotificationDate,
  });

  int get daysSinceLastSession => lastSessionDate == null
      ? 0
      : DateTime.now().difference(lastSessionDate!).inDays;

  int get daysUntilNotification => nextNotificationDate == null
      ? 0
      : nextNotificationDate!.difference(DateTime.now()).inDays;
}

class NotificationState {
  final bool isEnabled;
  final int thresholdDays;
  final bool permissionGranted;
  final List<PersonNotificationStatus> personStatuses;

  const NotificationState({
    required this.isEnabled,
    required this.thresholdDays,
    required this.permissionGranted,
    this.personStatuses = const [],
  });

  NotificationState copyWith({
    bool? isEnabled,
    int? thresholdDays,
    bool? permissionGranted,
    List<PersonNotificationStatus>? personStatuses,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      thresholdDays: thresholdDays ?? this.thresholdDays,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      personStatuses: personStatuses ?? this.personStatuses,
    );
  }
}

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  @override
  Future<NotificationState> build() async {
    return _load();
  }

  Future<NotificationState> _load() async {
    final settingsRepo = ref.read(notificationSettingsRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);

    final isEnabled = await settingsRepo.isEnabled();
    final thresholdDays = await settingsRepo.getThresholdDays();
    final permissionGranted = await Permission.notification.status.isGranted;

    final persons = ref.watch(familyProvider).valueOrNull?.persons ?? [];
    final personStatuses = await Future.wait(
      persons.map(
        (person) => _statusForPerson(
          person,
          sessionRepo: sessionRepo,
          notificationService: notificationService,
          isEnabled: isEnabled,
        ),
      ),
    );

    return NotificationState(
      isEnabled: isEnabled,
      thresholdDays: thresholdDays,
      permissionGranted: permissionGranted,
      personStatuses: personStatuses,
    );
  }

  Future<PersonNotificationStatus> _statusForPerson(
    PersonEntity person, {
    required SessionRepository sessionRepo,
    required NotificationService notificationService,
    required bool isEnabled,
  }) async {
    final lastSessionDate = await sessionRepo.getLastCompletedSessionDate(
      person.id,
    );
    final nextNotificationDate = isEnabled
        ? await notificationService.getScheduledDate(person.id)
        : null;
    return PersonNotificationStatus(
      personId: person.id,
      personName: person.name,
      lastSessionDate: lastSessionDate,
      nextNotificationDate: nextNotificationDate,
    );
  }

  /// Richiede il permesso e attiva le notifiche.
  /// Se il permesso è negato aggiorna permissionGranted = false.
  Future<void> requestPermissionAndEnable() async {
    final notificationService = ref.read(notificationServiceProvider);
    final granted = await notificationService.initialize();

    final settingsRepo = ref.read(notificationSettingsRepositoryProvider);
    await settingsRepo.setEnabled(granted);

    if (granted) {
      final persons = ref.read(familyProvider).valueOrNull?.persons ?? [];
      await rescheduleAll(persons);
    }

    state = await AsyncValue.guard(_load);
  }

  Future<void> setEnabled(bool value) async {
    final settingsRepo = ref.read(notificationSettingsRepositoryProvider);
    await settingsRepo.setEnabled(value);

    if (!value) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelAll();
    } else {
      final persons = ref.read(familyProvider).valueOrNull?.persons ?? [];
      await rescheduleAll(persons);
    }

    state = await AsyncValue.guard(_load);
  }

  Future<void> setThresholdDays(int days) async {
    final settingsRepo = ref.read(notificationSettingsRepositoryProvider);
    await settingsRepo.setThresholdDays(days);

    final current = state.valueOrNull;
    if (current?.isEnabled == true) {
      final persons = ref.read(familyProvider).valueOrNull?.persons ?? [];
      await rescheduleAll(persons);
    }

    state = await AsyncValue.guard(_load);
  }

  /// Reschedula la notifica per una persona dopo una sessione completata.
  /// Chiamato da CalendarNotifier — non tocca le notifiche delle altre persone.
  Future<void> rescheduleForPerson({
    required String personId,
    required String personName,
  }) async {
    final current = state.valueOrNull;
    if (current == null || !current.isEnabled || !current.permissionGranted) {
      return;
    }
    final notificationService = ref.read(notificationServiceProvider);
    final dueDate = DateTime.now().add(Duration(days: current.thresholdDays));

    await notificationService.cancelNotification(personId);
    await notificationService.scheduleInactivityNotification(
      personId: personId,
      personName: personName,
      dueDate: dueDate,
      thresholdDays: current.thresholdDays,
    );

    state = await AsyncValue.guard(_load);
  }

  /// Schedula le notifiche per tutte le persone.
  /// Chiamato quando si attivano le notifiche o si cambia la soglia.
  Future<void> rescheduleAll(List<PersonEntity> persons) async {
    final settingsRepo = ref.read(notificationSettingsRepositoryProvider);
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final thresholdDays = await settingsRepo.getThresholdDays();

    for (final person in persons) {
      final lastSessionDate = await sessionRepo.getLastCompletedSessionDate(
        person.id,
      );
      final baseDate = lastSessionDate ?? person.createdAt ?? DateTime.now();
      final dueDate = baseDate.add(Duration(days: thresholdDays));

      await notificationService.cancelNotification(person.id);
      await notificationService.scheduleInactivityNotification(
        personId: person.id,
        personName: person.name,
        dueDate: dueDate,
        thresholdDays: thresholdDays,
      );
    }
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );
