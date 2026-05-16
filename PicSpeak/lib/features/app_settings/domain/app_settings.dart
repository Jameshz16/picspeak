import 'package:flutter/material.dart';

class AppSettings {
  final String locale;
  final double voiceSpeed;
  final ThemeMode themeMode;

  const AppSettings({
    this.locale = 'es',
    this.voiceSpeed = 0.5,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    String? locale,
    double? voiceSpeed,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale,
      'voiceSpeed': voiceSpeed,
      'themeMode': themeMode.index,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      locale: json['locale'] as String? ?? 'es',
      voiceSpeed: (json['voiceSpeed'] as num?)?.toDouble() ?? 0.5,
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
    );
  }
}
