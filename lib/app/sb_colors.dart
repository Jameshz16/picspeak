import 'package:flutter/material.dart';

/// Soft Blue Design System — Color Palette for PicSpeak
///
/// Migrated from Neo-Brutalism to a calming, professional blue-centric palette.
class SbColors {
  SbColors._();

  // ---------------------------------------------------------------------------
  // Brand palette
  // ---------------------------------------------------------------------------

  /// Primary text — deep navy
  static const Color primaryText = Color(0xFF263D69);

  /// Accent blue — light blue for backgrounds and borders
  static const Color accentBlue = Color(0xFFB0CCFF);

  /// Light blue — very light blue for subtle backgrounds
  static const Color lightBlue = Color(0xFFDAE7FF);

  /// Accent gold — warm cream for highlights
  static const Color accentGold = Color(0xFFFFEEC9);

  /// Accent gold dark — deep gold for text on light backgrounds
  static const Color accentGoldDark = Color(0xFF946E1C);

  /// Accent gold light — very light gold for subtle backgrounds
  static const Color accentGoldLight = Color(0xFFFFF0CF);

  /// Accent gold medium — medium gold for badges and accents
  static const Color accentGoldMedium = Color(0xFFFADA93);

  /// Active blue — for active states and primary actions
  static const Color activeBlue = Color(0xFF3970DF);

  /// Dark blue — for dark mode primary elements
  static const Color darkBlue = Color(0xFF1C4694);

  // ---------------------------------------------------------------------------
  // Semantic tokens
  // ---------------------------------------------------------------------------

  /// Background and surface — white
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// On surface — navy text
  static const Color onSurface = Color(0xFF263D69);

  /// Outline — light blue borders
  static const Color outline = Color(0xFFB0CCFF);

  /// Divider — neutral gray
  static const Color divider = Color(0xFFD9D9D9);

  /// Error — red for destructive actions
  static const Color error = Color(0xFFE5484D);

  /// On error — white text on error backgrounds
  static const Color onError = Color(0xFFFFFFFF);
}
