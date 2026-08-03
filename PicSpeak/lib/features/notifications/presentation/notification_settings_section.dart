import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_settings/data/settings_providers.dart';
import '../../app_settings/domain/app_settings.dart';
import '../data/notification_providers.dart';
import '../domain/notification_repository.dart';

class NotificationSettingsSection extends ConsumerStatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  ConsumerState<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends ConsumerState<NotificationSettingsSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final repository = ref.read(settingsRepositoryProvider);
    final notificationRepo = ref.read(notificationRepositoryProvider);

    return settingsAsync.when(
      data: (settings) => _buildSection(context, settings, repository, notificationRepo),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSection(
    BuildContext context,
    AppSettings settings,
    dynamic repository,
    NotificationRepository notificationRepo,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Notifications'),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Master toggle
                SwitchListTile(
                  title: const Text(
                    'Enable Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Receive SRS and streak reminders'),
                  secondary: const Icon(Icons.notifications),
                  value: settings.notificationsEnabled,
                  onChanged: _isLoading
                      ? null
                      : (value) => _toggleMaster(
                          repository, notificationRepo, settings, value),
                ),
                if (settings.notificationsEnabled) ...[
                  const Divider(),
                  // SRS reminders toggle
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: SwitchListTile(
                      title: const Text('SRS Review Reminders'),
                      subtitle: const Text('Remind you to review due cards'),
                      value: settings.srsRemindersEnabled,
                      onChanged: (value) {
                        final updated =
                            settings.copyWith(srsRemindersEnabled: value);
                        repository.save(updated);
                        _rescheduleAll(notificationRepo, updated);
                      },
                    ),
                  ),
                  // Streak reminders toggle
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: SwitchListTile(
                      title: const Text('Streak Reminders'),
                      subtitle: const Text('Protect your learning streak'),
                      value: settings.streakRemindersEnabled,
                      onChanged: (value) {
                        final updated =
                            settings.copyWith(streakRemindersEnabled: value);
                        repository.save(updated);
                        _rescheduleAll(notificationRepo, updated);
                      },
                    ),
                  ),
                  const Divider(),
                  // Quiet hours toggle
                  SwitchListTile(
                    title: const Text('Quiet Hours'),
                    subtitle: const Text('No notifications between 9 PM and 8 AM'),
                    secondary: const Icon(Icons.nightlight_round),
                    value: settings.quietHoursEnabled,
                    onChanged: (value) {
                      final updated =
                          settings.copyWith(quietHoursEnabled: value);
                      repository.save(updated);
                      _rescheduleAll(notificationRepo, updated);
                    },
                  ),
                  const Divider(),
                  // Custom schedule time
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Custom Schedule Time'),
                    subtitle: Text(
                      settings.customScheduleTime != null
                          ? 'Set to ${settings.customScheduleTime}'
                          : 'Using learned schedule time',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (settings.customScheduleTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              final updated = settings.copyWith(
                                clearCustomScheduleTime: true,
                              );
                              repository.save(updated);
                              _rescheduleAll(notificationRepo, updated);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _pickTime(
                              context, repository, notificationRepo, settings),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleMaster(
    dynamic repository,
    NotificationRepository notificationRepo,
    AppSettings settings,
    bool enable,
  ) async {
    setState(() => _isLoading = true);
    try {
      if (enable) {
        // Request permission first
        final granted = await notificationRepo.requestPermission();
        if (!granted) {
          // Permission denied, don't enable
          return;
        }
      }

      final updated = settings.copyWith(notificationsEnabled: enable);
      await repository.save(updated);

      if (enable) {
        await _rescheduleAll(notificationRepo, updated);
      } else {
        await notificationRepo.cancelAll();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rescheduleAll(
    NotificationRepository notificationRepo,
    AppSettings settings,
  ) async {
    try {
      await notificationRepo.rescheduleAll(settings: settings);
    } catch (e) {
      // Silent failure - notification scheduling can fail without crashing
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    dynamic repository,
    NotificationRepository notificationRepo,
    AppSettings settings,
  ) async {
    final initialTime = settings.customScheduleTime != null
        ? _parseTimeOfDay(settings.customScheduleTime!)
        : const TimeOfDay(hour: 16, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final updated = settings.copyWith(customScheduleTime: timeStr);
      await repository.save(updated);
      await _rescheduleAll(notificationRepo, updated);
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 16;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 16, minute: 0);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}