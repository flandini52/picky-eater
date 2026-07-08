import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _minThresholdDays = 1;
  static const _maxThresholdDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifiche')),
      body: notificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.isEnabled,
              activeThumbColor: AppColors.salvia,
              title: const Text(
                'Attiva promemoria',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Ricevilo se non registri sessioni per alcuni giorni.',
              ),
              onChanged: (value) => _onToggle(ref, value),
            ),
            if (state.isEnabled) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ricordami dopo:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.salvia,
                        onPressed: state.thresholdDays > _minThresholdDays
                            ? () => ref
                                  .read(notificationProvider.notifier)
                                  .setThresholdDays(state.thresholdDays - 1)
                            : null,
                      ),
                      Text(
                        '${state.thresholdDays} giorni',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.salvia,
                        onPressed: state.thresholdDays < _maxThresholdDays
                            ? () => ref
                                  .read(notificationProvider.notifier)
                                  .setThresholdDays(state.thresholdDays + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'STATO PROMEMORIA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              if (state.personStatuses.isEmpty)
                const Text('Nessuna persona ancora.')
              else
                ...state.personStatuses.map(
                  (status) => _PersonStatusTile(status: status),
                ),
            ],
            if (!state.permissionGranted) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pesca.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.pesca),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(child: Text('Se non vedi le notifiche')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(notificationServiceProvider)
                          .openSystemSettings(),
                      child: const Text('Apri impostazioni telefono'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onToggle(WidgetRef ref, bool value) async {
    final notifier = ref.read(notificationProvider.notifier);
    if (value) {
      await notifier.requestPermissionAndEnable();
    } else {
      await notifier.setEnabled(false);
    }
  }
}

class _PersonStatusTile extends StatelessWidget {
  final PersonNotificationStatus status;

  const _PersonStatusTile({required this.status});

  String get _lastSessionLabel {
    if (status.lastSessionDate == null) return 'Nessuna sessione registrata';
    final days = status.daysSinceLastSession;
    if (days <= 0) return 'Ultima sessione: oggi';
    if (days == 1) return 'Ultima sessione: ieri';
    return 'Ultima sessione: $days giorni fa';
  }

  String get _nextNotificationLabel {
    if (status.nextNotificationDate == null) return '';
    final days = status.daysUntilNotification;
    if (days <= 0) return 'Prossimo promemoria: oggi';
    return 'Prossimo promemoria: tra $days giorni';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.personName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _lastSessionLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (status.nextNotificationDate != null)
            Text(
              _nextNotificationLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
