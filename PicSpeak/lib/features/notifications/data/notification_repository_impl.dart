import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../../app_settings/domain/app_settings.dart';
import '../../flashcard_review/domain/flashcard_repository.dart';
import '../../stats/data/stats_repository.dart';
import '../domain/notification_repository.dart';
import 'notification_permissions.dart';
import 'usage_time_tracker.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final SharedPreferences _prefs;
  final UsageTimeTracker _usageTimeTracker;
  final NotificationPermissions _permissions;
  final FlashcardRepository _flashcardRepository;
  final StatsRepository _statsRepository;

  static const _androidChannelId = 'pic_speak_reminders';
  static const _androidChannelName = 'PicSpeak Reminders';
  static const _srsNotificationId = 0;
  static const _streakNotificationId = 1;

  NotificationRepositoryImpl({
    required FlutterLocalNotificationsPlugin notificationsPlugin,
    required SharedPreferences prefs,
    required UsageTimeTracker usageTimeTracker,
    required NotificationPermissions permissions,
    required FlashcardRepository flashcardRepository,
    required StatsRepository statsRepository,
  })  : _notificationsPlugin = notificationsPlugin,
        _prefs = prefs,
        _usageTimeTracker = usageTimeTracker,
        _permissions = permissions,
        _flashcardRepository = flashcardRepository,
        _statsRepository = statsRepository;

  /// Initializes time zones. Must be called once at app startup.
  static void initialize() {
    tz.initializeTimeZones();
  }

  /// Initializes the notification plugin with platform-specific settings.
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create Android notification channel
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
        ),
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    final status = await _permissions.requestPermission();
    return status == NotificationPermissionStatus.granted;
  }

  @override
  Future<bool> getPermissionStatus() async {
    return _permissions.isGranted;
  }

  @override
  Future<void> scheduleSrsReminder(int dueCount) async {
    if (dueCount <= 0) return;

    final hasPermission = await getPermissionStatus();
    if (!hasPermission) return;

    // Check daily cap
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final capKey = 'notif_sent_srs_$today';
    if (_prefs.getBool(capKey) == true) return;

    // Get schedule time
    final scheduleTime = await _getScheduledTime();

    // Apply quiet hours
    final adjustedTime = _applyQuietHours(scheduleTime);

    // Schedule notification
    final scheduledDate = _nextInstanceOfTime(adjustedTime);

    await _notificationsPlugin.zonedSchedule(
      _srsNotificationId,
      'Time to Review!',
      'You have $dueCount cards to review today.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _prefs.setBool(capKey, true);
  }

  @override
  Future<void> scheduleStreakReminder(int streakDays) async {
    if (streakDays < 2) return;

    final hasPermission = await getPermissionStatus();
    if (!hasPermission) return;

    // Check daily cap
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final capKey = 'notif_sent_streak_$today';
    if (_prefs.getBool(capKey) == true) return;

    // Get schedule time
    final scheduleTime = await _getScheduledTime();

    // Apply quiet hours
    final adjustedTime = _applyQuietHours(scheduleTime);

    // Schedule notification
    final scheduledDate = _nextInstanceOfTime(adjustedTime);

    await _notificationsPlugin.zonedSchedule(
      _streakNotificationId,
      'Keep your streak!',
      "You're on a $streakDays-day streak! Don't lose it.",
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _prefs.setBool(capKey, true);
  }

  @override
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  @override
  Future<void> cancelByType(String type) async {
    if (type == 'srs') {
      await _notificationsPlugin.cancel(_srsNotificationId);
    } else if (type == 'streak') {
      await _notificationsPlugin.cancel(_streakNotificationId);
    }
  }

  /// Reschedules all notifications based on current settings and data.
  Future<void> rescheduleAll({
    required AppSettings settings,
  }) async {
    if (!settings.notificationsEnabled) {
      await cancelAll();
      return;
    }

    // Schedule SRS reminder if enabled
    if (settings.srsRemindersEnabled) {
      final dueCount = await _flashcardRepository.getDueCount();
      await scheduleSrsReminder(dueCount);
    }

    // Schedule streak reminder if enabled
    if (settings.streakRemindersEnabled) {
      // StatsRepository doesn't expose streak directly; we need to compute it
      // For now, we'll read from SharedPreferences
      final streak = _prefs.getInt('study_streak') ?? 0;
      await scheduleStreakReminder(streak);
    }
  }

  Future<TimeOfDay> _getScheduledTime() async {
    return _usageTimeTracker.getScheduleTime();
  }

  TimeOfDay _applyQuietHours(TimeOfDay time) {
    final hour = time.hour;

    // If time is between 21:00 and 08:00, defer to 08:00
    if (hour >= 21 || hour < 8) {
      return const TimeOfDay(hour: 8, minute: 0);
    }

    return time;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
