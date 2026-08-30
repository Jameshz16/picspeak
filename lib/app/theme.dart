import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Neo-Brutalism Design Tokens — PicSpeak
// Palette: Electric Blue / Vivid Purple / Hot Pink
// ---------------------------------------------------------------------------

class NbColors {
  NbColors._();

  // Brand palette
  static const Color primary        = Color(0xFF2E5BFF); // Electric Blue
  static const Color secondary      = Color(0xFF9D50FF); // Vivid Purple
  static const Color tertiary       = Color(0xFFFF3DAB); // Hot Pink
  static const Color outline        = Color(0xFF0F0F0F); // near-black borders
  static const Color surface        = Color(0xFFFAF8FF); // lavender-cream
  static const Color surfaceBright  = Color(0xFFFFFFFF);
  static const Color onSurface      = Color(0xFF12141D); // deep navy
  static const Color error          = Color(0xFFE5484D);
  static const Color onError        = Color(0xFFFFFFFF);
}

/// Hard offset shadow — the signature Neo-Brutalism effect.
class NbShadows {
  NbShadows._();

  static const BoxShadow hard = BoxShadow(
    color: NbColors.outline,
    offset: Offset(4, 4),
    blurRadius: 0,
    spreadRadius: 0,
  );

  /// Pressed state — shadow shrinks.
  static const BoxShadow pressed = BoxShadow(
    color: NbColors.outline,
    offset: Offset(2, 2),
    blurRadius: 0,
    spreadRadius: 0,
  );
}

/// Corner radius — sharp, 4px base.
class NbRadius {
  NbRadius._();

  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double full = 9999;
}

// ---------------------------------------------------------------------------
// Theme Mode Notifier (unchanged API)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// ColorScheme — explicit, no fromSeed
// ---------------------------------------------------------------------------

final ColorScheme _lightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: NbColors.primary,
  onPrimary: NbColors.onError,
  primaryContainer: NbColors.primary,
  onPrimaryContainer: NbColors.onError,
  secondary: NbColors.secondary,
  onSecondary: NbColors.onError,
  secondaryContainer: NbColors.secondary,
  onSecondaryContainer: NbColors.onError,
  tertiary: NbColors.tertiary,
  onTertiary: NbColors.onError,
  tertiaryContainer: NbColors.tertiary,
  onTertiaryContainer: NbColors.onError,
  error: NbColors.error,
  onError: NbColors.onError,
  surface: NbColors.surface,
  onSurface: NbColors.onSurface,
  outline: NbColors.outline,
  outlineVariant: NbColors.outline,
  surfaceContainerHighest: const Color(0xFFE4E2F3),
  surfaceContainerHigh: const Color(0xFFECEAF9),
  surfaceContainer: const Color(0xFFF4F2FF),
  surfaceContainerLow: NbColors.surface,
  surfaceContainerLowest: NbColors.surfaceBright,
  surfaceTint: NbColors.primary,
);

final ColorScheme _darkColorScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: NbColors.primary,
  onPrimary: NbColors.onError,
  primaryContainer: NbColors.primary,
  onPrimaryContainer: NbColors.onError,
  secondary: NbColors.secondary,
  onSecondary: NbColors.onError,
  secondaryContainer: NbColors.secondary,
  onSecondaryContainer: NbColors.onError,
  tertiary: NbColors.tertiary,
  onTertiary: NbColors.onError,
  tertiaryContainer: NbColors.tertiary,
  onTertiaryContainer: NbColors.onError,
  error: NbColors.error,
  onError: NbColors.onError,
  surface: NbColors.onSurface,
  onSurface: NbColors.surface,
  outline: NbColors.outline,
  outlineVariant: NbColors.outline,
  surfaceContainerHighest: const Color(0xFF1E2029),
  surfaceContainerHigh: const Color(0xFF262830),
  surfaceContainer: const Color(0xFF2E303A),
  surfaceContainerLow: const Color(0xFF12141D),
  surfaceContainerLowest: const Color(0xFF0A0A10),
  surfaceTint: NbColors.primary,
);

// ---------------------------------------------------------------------------
// Typography — Lexend 800 headlines, Inter 500/700 body
// ---------------------------------------------------------------------------

TextTheme _buildTextTheme(Brightness brightness) {
  final Color textColor =
      brightness == Brightness.light ? NbColors.onSurface : NbColors.surface;

  return TextTheme(
    displayLarge: GoogleFonts.lexend(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.02,
      color: textColor,
    ),
    displayMedium: GoogleFonts.lexend(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: textColor,
    ),
    displaySmall: GoogleFonts.lexend(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: textColor,
    ),
    headlineLarge: GoogleFonts.lexend(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      height: 1.2,
      color: textColor,
    ),
    headlineMedium: GoogleFonts.lexend(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: textColor,
    ),
    headlineSmall: GoogleFonts.lexend(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      height: 1.3,
      color: textColor,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: textColor,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: textColor,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: textColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: textColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: textColor,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.02,
      color: textColor,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.02,
      color: textColor,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.02,
      color: textColor,
    ),
  );
}

// ---------------------------------------------------------------------------
// ThemeData
// ---------------------------------------------------------------------------

final ThemeData lightTheme = ThemeData(
  colorScheme: _lightColorScheme,
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: NbColors.surface,
  textTheme: _buildTextTheme(Brightness.light),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: NbColors.surface,
    foregroundColor: NbColors.onSurface,
    titleTextStyle: GoogleFonts.lexend(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: NbColors.onSurface,
    ),
    shape: const Border(
      bottom: BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: NbColors.surfaceBright,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
    margin: const EdgeInsets.all(8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: NbColors.primary,
      foregroundColor: NbColors.onError,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NbRadius.xs),
        side: const BorderSide(color: NbColors.outline, width: 2),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: NbColors.onSurface,
      backgroundColor: NbColors.surfaceBright,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NbRadius.xs),
      ),
      side: const BorderSide(color: NbColors.outline, width: 2),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: NbColors.primary,
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: NbColors.primary,
    foregroundColor: NbColors.onError,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(NbRadius.sm)),
      side: BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: NbColors.surfaceBright,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.outline, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.outline, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.error, width: 2),
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NbColors.onSurface.withValues(alpha: 0.7),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: NbColors.tertiary,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: NbColors.onError,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: NbColors.onSurface,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NbColors.surface,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: NbColors.surfaceBright,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.sm),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: NbColors.surfaceBright,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(NbRadius.sm)),
      side: BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: NbColors.primary,
    linearTrackColor: NbColors.outline,
  ),
  dividerTheme: const DividerThemeData(
    color: NbColors.outline,
    thickness: 2,
    space: 0,
  ),
);

final ThemeData darkTheme = ThemeData(
  colorScheme: _darkColorScheme,
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: NbColors.onSurface,
  textTheme: _buildTextTheme(Brightness.dark),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: NbColors.onSurface,
    foregroundColor: NbColors.surface,
    titleTextStyle: GoogleFonts.lexend(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: NbColors.surface,
    ),
    shape: const Border(
      bottom: BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF1E2029),
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
    margin: const EdgeInsets.all(8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: NbColors.primary,
      foregroundColor: NbColors.onError,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NbRadius.xs),
        side: const BorderSide(color: NbColors.outline, width: 2),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: NbColors.surface,
      backgroundColor: const Color(0xFF1E2029),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NbRadius.xs),
      ),
      side: const BorderSide(color: NbColors.outline, width: 2),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: NbColors.primary,
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: NbColors.primary,
    foregroundColor: NbColors.onError,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(NbRadius.sm)),
      side: BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E2029),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.outline, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.outline, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      borderSide: const BorderSide(color: NbColors.error, width: 2),
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NbColors.surface.withValues(alpha: 0.7),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: NbColors.tertiary,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: NbColors.onError,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: NbColors.surface,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: NbColors.onSurface,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.xs),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1E2029),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NbRadius.sm),
      side: const BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1E2029),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(NbRadius.sm)),
      side: BorderSide(color: NbColors.outline, width: 2),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: NbColors.primary,
    linearTrackColor: NbColors.outline,
  ),
  dividerTheme: const DividerThemeData(
    color: NbColors.outline,
    thickness: 2,
    space: 0,
  ),
);
