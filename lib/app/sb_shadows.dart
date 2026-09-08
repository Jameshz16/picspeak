import 'package:flutter/material.dart';
import 'sb_colors.dart';

/// Soft Blue Design System — Shadows
///
/// Gentle, blurred shadows replacing the hard Neo-Brutalism drop shadows.
class SbShadows {
  SbShadows._();

  /// Standard soft shadow for cards and elevated elements.
  static const BoxShadow soft = BoxShadow(
    color: Color(0x0A263D69), // primaryText at 4% opacity
    offset: Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
  );

  /// Pressed state — even softer, smaller shadow.
  static const BoxShadow pressed = BoxShadow(
    color: Color(0x05263D69), // primaryText at 2% opacity
    offset: Offset(0, 2),
    blurRadius: 4,
    spreadRadius: 0,
  );
}
