import 'package:flutter/material.dart';

class AppSettings {
  final String locale;
  final double voiceSpeed;
  final ThemeMode themeMode;

  // Notification preferences
  final bool notificationsEnabled;
  final bool srsRemindersEnabled;
  final bool streakRemindersEnabled;
  final bool quietHoursEnabled;
  final String? customScheduleTime; // "HH:mm" format, null = use learned time

  const AppSettings({
    this.locale = 'es',
    this.voiceSpeed = 1.0,
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = false,
    this.srsRemindersEnabled = true,
    this.streakRemindersEnabled = true,
    this.quietHoursEnabled = true,
    this.customScheduleTime,
  });

  AppSettings copyWith({
    String? locale,
    double? voiceSpeed,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? srsRemindersEnabled,
    bool? streakRemindersEnabled,
    bool? quietHoursEnabled,
    String? customScheduleTime,
    bool clearCustomScheduleTime = false,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      srsRemindersEnabled: srsRemindersEnabled ?? this.srsRemindersEnabled,
      streakRemindersEnabled:
          streakRemindersEnabled ?? this.streakRemindersEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      customScheduleTime: clearCustomScheduleTime
          ? null
          : (customScheduleTime ?? this.customScheduleTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale,
      'voiceSpeed': voiceSpeed,
      'themeMode': themeMode.index,
      'notificationsEnabled': notificationsEnabled,
      'srsRemindersEnabled': srsRemindersEnabled,
      'streakRemindersEnabled': streakRemindersEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'customScheduleTime': customScheduleTime,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      locale: json['locale'] as String? ?? 'es',
      voiceSpeed: (json['voiceSpeed'] as num?)?.toDouble() ?? 1.0,
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      srsRemindersEnabled: json['srsRemindersEnabled'] as bool? ?? true,
      streakRemindersEnabled: json['streakRemindersEnabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
      customScheduleTime: json['customScheduleTime'] as String?,
    );
  }
}
