import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app_settings/data/settings_providers.dart';
import '../../app_settings/domain/app_settings.dart';
import '../data/notification_providers.dart';
import '../domain/notification_repository.dart';
import '../domain/notification_permission_status.dart';

class NotificationSettingsSection extends ConsumerStatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  ConsumerState<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends ConsumerState<NotificationSettingsSection>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  NotificationPermissionStatus? _permissionDeniedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _revalidatePermissionOnResume();
    }
  }

  /// When the user returns from OS Settings (after openAppSettings()),
  /// re-read the actual OS permission and clear the denied banner if
  /// permission is now granted.
  void _revalidatePermissionOnResume() {
    if (!mounted || _permissionDeniedStatus == null) return;

    final notificationRepo = ref.read(notificationRepositoryProvider);
    notificationRepo.getPermissionStatus().then((granted) {
      if (!mounted) return;
      if (granted && _permissionDeniedStatus != null) {
        setState(() => _permissionDeniedStatus = null);
        // Re-sync the settings toggle: if notificationsEnabled was on but
        // banner was blocking, the toggle is already on (correct). If the
        // user denied externally while enabled, the banner re-appears on
        // next build naturally — no extra flip needed.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                if (_permissionDeniedStatus != null)
                  _PermissionDeniedBanner(
                    status: _permissionDeniedStatus!,
                    onRetry: () => _toggleMaster(
                        repository, notificationRepo, settings, true),
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
    setState(() {
      _isLoading = true;
      _permissionDeniedStatus = null;
    });
    try {
      if (enable) {
        // Request permission with detailed status
        final status = await notificationRepo.requestPermissionDetailed();
        if (status != NotificationPermissionStatus.granted) {
          if (mounted) {
            setState(() => _permissionDeniedStatus = status);
          }
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

/// Banner shown when notification permission is denied or permanently denied.
/// Mirrors the camera permission UX pattern from camera_screen.dart.
class _PermissionDeniedBanner extends StatelessWidget {
  final NotificationPermissionStatus status;
  final VoidCallback onRetry;

  const _PermissionDeniedBanner({
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isPermanently =
        status == NotificationPermissionStatus.permanentlyDenied;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isPermanently ? Icons.block : Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPermanently
                      ? 'Notification permission is permanently denied. Please enable it in app settings to receive reminders.'
                      : 'Notification permission was denied. Tap below to try again.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isPermanently)
            TextButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Open Settings'),
            )
          else
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}