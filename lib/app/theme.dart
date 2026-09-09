import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sb_colors.dart';
import 'sb_shadows.dart';
import 'sb_radius.dart';

// ---------------------------------------------------------------------------
// Backward-compatible aliases for Neo-Brutalism tokens.
// These allow existing feature files to compile while migrating to Sb*.
// Will be removed after all features are migrated to Soft Blue.
// ---------------------------------------------------------------------------

class NbColors {
  NbColors._();
  static const Color primary = SbColors.activeBlue;
  static const Color secondary = SbColors.accentGold;
  static const Color tertiary = SbColors.accentBlue;
  static const Color outline = SbColors.outline;
  static const Color surface = SbColors.surface;
  static const Color surfaceBright = SbColors.surface;
  static const Color onSurface = SbColors.onSurface;
  static const Color error = SbColors.error;
  static const Color onError = SbColors.onError;
}

class NbShadows {
  NbShadows._();
  static const BoxShadow hard = SbShadows.soft;
  static const BoxShadow pressed = SbShadows.pressed;
}

class NbRadius {
  NbRadius._();
  static const double xs = SbRadius.secondary;
  static const double sm = SbRadius.primary;
  static const double md = SbRadius.medium;
  static const double lg = SbRadius.large;
  static const double full = SbRadius.full;
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
// ColorScheme — Soft Blue
// ---------------------------------------------------------------------------

final ColorScheme _lightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: SbColors.activeBlue,
  onPrimary: SbColors.onError,
  primaryContainer: SbColors.lightBlue,
  onPrimaryContainer: SbColors.darkBlue,
  secondary: SbColors.accentGold,
  onSecondary: SbColors.accentGoldDark,
  secondaryContainer: SbColors.accentGoldLight,
  onSecondaryContainer: SbColors.accentGoldDark,
  tertiary: SbColors.accentBlue,
  onTertiary: SbColors.primaryText,
  tertiaryContainer: SbColors.lightBlue,
  onTertiaryContainer: SbColors.primaryText,
  error: SbColors.error,
  onError: SbColors.onError,
  surface: SbColors.surface,
  onSurface: SbColors.onSurface,
  outline: SbColors.outline,
  outlineVariant: SbColors.accentBlue.withValues(alpha: 0.4),
  surfaceContainerHighest: const Color(0xFFEEF2FA),
  surfaceContainerHigh: const Color(0xFFF3F6FC),
  surfaceContainer: const Color(0xFFF8F9FE),
  surfaceContainerLow: SbColors.surface,
  surfaceContainerLowest: SbColors.background,
  surfaceTint: SbColors.activeBlue,
);

final ColorScheme _darkColorScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: SbColors.accentBlue,
  onPrimary: SbColors.primaryText,
  primaryContainer: SbColors.darkBlue,
  onPrimaryContainer: SbColors.lightBlue,
  secondary: SbColors.accentGoldMedium,
  onSecondary: SbColors.primaryText,
  secondaryContainer: SbColors.accentGoldDark,
  onSecondaryContainer: SbColors.accentGoldLight,
  tertiary: SbColors.accentBlue,
  onTertiary: SbColors.primaryText,
  tertiaryContainer: SbColors.darkBlue,
  onTertiaryContainer: SbColors.lightBlue,
  error: SbColors.error,
  onError: SbColors.onError,
  surface: const Color(0xFF1A2440),
  onSurface: SbColors.lightBlue,
  outline: SbColors.darkBlue,
  outlineVariant: const Color(0xFF2A3E6B),
  surfaceContainerHighest: const Color(0xFF1E2E52),
  surfaceContainerHigh: const Color(0xFF233558),
  surfaceContainer: const Color(0xFF2A3E6B),
  surfaceContainerLow: const Color(0xFF162038),
  surfaceContainerLowest: const Color(0xFF0F1728),
  surfaceTint: SbColors.accentBlue,
);

// ---------------------------------------------------------------------------
// Typography — LINE Seed JP headlines, Inter body
// ---------------------------------------------------------------------------

TextTheme _buildTextTheme(Brightness brightness) {
  final Color textColor =
      brightness == Brightness.light ? SbColors.onSurface : SbColors.lightBlue;

  return TextTheme(
    displayLarge: GoogleFonts.lineSeedJp(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.02,
      color: textColor,
    ),
    displayMedium: GoogleFonts.lineSeedJp(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: textColor,
    ),
    displaySmall: GoogleFonts.lineSeedJp(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.2,
      color: textColor,
    ),
    headlineLarge: GoogleFonts.lineSeedJp(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: textColor,
    ),
    headlineMedium: GoogleFonts.lineSeedJp(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: textColor,
    ),
    headlineSmall: GoogleFonts.lineSeedJp(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.35,
      color: textColor,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: textColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: textColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: textColor,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.02,
      color: textColor,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.02,
      color: textColor,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
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
  scaffoldBackgroundColor: SbColors.background,
  textTheme: _buildTextTheme(Brightness.light),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: SbColors.background,
    foregroundColor: SbColors.onSurface,
    titleTextStyle: GoogleFonts.lineSeedJp(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: SbColors.onSurface,
    ),
    shape: Border(
      bottom: BorderSide(color: SbColors.outline.withValues(alpha: 0.3), width: 1),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: SbColors.surface,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.primary),
      side: BorderSide(color: SbColors.outline.withValues(alpha: 0.3), width: 1),
    ),
    margin: const EdgeInsets.all(8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SbColors.activeBlue,
      foregroundColor: SbColors.onError,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.primary),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: SbColors.activeBlue,
      backgroundColor: SbColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.primary),
      ),
      side: const BorderSide(color: SbColors.outline, width: 1),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: SbColors.activeBlue,
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: SbColors.activeBlue,
    foregroundColor: SbColors.onError,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.medium),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SbColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.outline, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.outline, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.activeBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.error, width: 1),
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: SbColors.onSurface.withValues(alpha: 0.6),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: SbColors.lightBlue,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: SbColors.activeBlue,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: SbColors.primaryText,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: SbColors.surface,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.primary),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: SbColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.medium),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: SbColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SbRadius.large),
      ),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: SbColors.activeBlue,
    linearTrackColor: SbColors.lightBlue,
  ),
  dividerTheme: DividerThemeData(
    color: SbColors.divider,
    thickness: 1,
    space: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: SbColors.lightBlue,
    indicatorColor: SbColors.activeBlue.withValues(alpha: 0.15),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: SbColors.activeBlue, size: 24);
      }
      return IconThemeData(
        color: SbColors.activeBlue.withValues(alpha: 0.5),
        size: 24,
      );
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final style = GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
      if (states.contains(WidgetState.selected)) {
        return style.copyWith(color: SbColors.activeBlue);
      }
      return style.copyWith(
        color: SbColors.activeBlue.withValues(alpha: 0.5),
      );
    }),
    height: 64,
  ),
);

final ThemeData darkTheme = ThemeData(
  colorScheme: _darkColorScheme,
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0F1728),
  textTheme: _buildTextTheme(Brightness.dark),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: const Color(0xFF0F1728),
    foregroundColor: SbColors.lightBlue,
    titleTextStyle: GoogleFonts.lineSeedJp(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: SbColors.lightBlue,
    ),
    shape: Border(
      bottom: BorderSide(color: SbColors.darkBlue.withValues(alpha: 0.5), width: 1),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF1E2E52),
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.primary),
      side: BorderSide(color: SbColors.darkBlue.withValues(alpha: 0.5), width: 1),
    ),
    margin: const EdgeInsets.all(8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SbColors.activeBlue,
      foregroundColor: SbColors.onError,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.primary),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: SbColors.accentBlue,
      backgroundColor: const Color(0xFF1E2E52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SbRadius.primary),
      ),
      side: const BorderSide(color: SbColors.darkBlue, width: 1),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: SbColors.accentBlue,
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: SbColors.activeBlue,
    foregroundColor: SbColors.onError,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.medium),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E2E52),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.darkBlue, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.darkBlue, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.accentBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
      borderSide: const BorderSide(color: SbColors.error, width: 1),
    ),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: SbColors.lightBlue.withValues(alpha: 0.6),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: SbColors.darkBlue,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: SbColors.accentBlue,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.secondary),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: SbColors.lightBlue,
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: SbColors.primaryText,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.primary),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1E2E52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SbRadius.medium),
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: const Color(0xFF1E2E52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SbRadius.large),
      ),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: SbColors.accentBlue,
    linearTrackColor: SbColors.darkBlue,
  ),
  dividerTheme: DividerThemeData(
    color: SbColors.darkBlue,
    thickness: 1,
    space: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF162038),
    indicatorColor: SbColors.accentBlue.withValues(alpha: 0.2),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: SbColors.accentBlue, size: 24);
      }
      return IconThemeData(
        color: SbColors.accentBlue.withValues(alpha: 0.5),
        size: 24,
      );
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final style = GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );
      if (states.contains(WidgetState.selected)) {
        return style.copyWith(color: SbColors.accentBlue);
      }
      return style.copyWith(
        color: SbColors.accentBlue.withValues(alpha: 0.5),
      );
    }),
    height: 64,
  ),
);
