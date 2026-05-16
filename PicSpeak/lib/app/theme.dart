import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setTheme(ThemeMode mode) => state = mode;

  void toggle() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFFF8C42),
  brightness: Brightness.light,
);

final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFFF8C42),
  brightness: Brightness.dark,
);

final ThemeData lightTheme = ThemeData(
  colorScheme: _lightColorScheme,
  useMaterial3: true,
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: _lightColorScheme.primaryContainer,
    foregroundColor: _lightColorScheme.onPrimaryContainer,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _lightColorScheme.primary,
    foregroundColor: _lightColorScheme.onPrimary,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
  ),
);

final ThemeData darkTheme = ThemeData(
  colorScheme: _darkColorScheme,
  useMaterial3: true,
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: _darkColorScheme.primaryContainer,
    foregroundColor: _darkColorScheme.onPrimaryContainer,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _darkColorScheme.primary,
    foregroundColor: _darkColorScheme.onPrimary,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
  ),
);
