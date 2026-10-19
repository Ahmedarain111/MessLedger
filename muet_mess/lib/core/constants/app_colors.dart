import 'package:flutter/material.dart';

/// Central color palette. Widgets must use [AppColors] (via the theme /
/// `AppTokens`) or theme colors, never hard-coded Color literals.
///
/// Brand direction: deep indigo primary, saffron accent, warm-neutral
/// surfaces in light mode and an ink-blue surface stack in dark mode.
class AppColors {
  AppColors._();

  // ---- Brand -------------------------------------------------------------
  static const primary = Color(0xFF3730A3);
  static const primaryLight = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF1E1B4B);
  static const primaryOnDark = Color(0xFF9195FB);
  static const secondary = Color(0xFF0D9488);
  static const accent = Color(0xFFF59E0B);

  // ---- Semantic base colors (mid-tone: readable on light and dark) -------
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);
  static const pending = Color(0xFFCA8A04);
  static const disputed = Color(0xFF9333EA);
  static const overdue = Color(0xFFEA580C);

  // ---- Shift colors ------------------------------------------------------
  static const shiftBreakfast = Color(0xFFF59E0B);
  static const shiftLunch = Color(0xFF0D9488);
  static const shiftDinner = Color(0xFF6D5BD0);

  // ---- Light surfaces ----------------------------------------------------
  static const lightBackground = Color(0xFFF6F5F2);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFEFEEEA);
  static const lightOnSurface = Color(0xFF1B1B2F);
  static const lightMuted = Color(0xFF6B6F85);
  static const borderLight = Color(0xFFE6E4DE);
  static const primaryContainerLight = Color(0xFFE4E6FF);
  static const secondaryContainerLight = Color(0xFFD3F1EC);
  static const tertiaryContainerLight = Color(0xFFFFEFC7);

  // ---- Dark surfaces -----------------------------------------------------
  static const darkBackground = Color(0xFF0D0F1E);
  static const darkSurface = Color(0xFF161A2D);
  static const darkSurfaceAlt = Color(0xFF1F2440);
  static const darkOnSurface = Color(0xFFE8EAF6);
  static const darkMuted = Color(0xFF9AA0BC);
  static const borderDark = Color(0xFF2A3052);
  static const primaryContainerDark = Color(0xFF2B2E66);
  static const secondaryContainerDark = Color(0xFF123F3B);
  static const tertiaryContainerDark = Color(0xFF4A3410);

  // ---- Legacy status tints (kept for compatibility) ----------------------
  static const successBg = Color(0xFFDCFCE7);
  static const dangerBg = Color(0xFFFEE2E2);
  static const warningBg = Color(0xFFFEF3C7);
  static const successText = Color(0xFF15803D);
  static const dangerText = Color(0xFFB91C1C);
  static const warningText = Color(0xFFB45309);
  static const dangerOnDark = Color(0xFFF87171);
  static const dangerBgDark = Color(0xFF4A1D22);

  // ---- Hero gradients ----------------------------------------------------
  static const heroStartLight = Color(0xFF3730A3);
  static const heroEndLight = Color(0xFF6256E0);
  static const heroStartDark = Color(0xFF3A36B8);
  static const heroEndDark = Color(0xFF1F1C5E);
  static const owingStart = Color(0xFFEA580C);
  static const owingEnd = Color(0xFFBE123C);

  static const inverseSurfaceLight = Color(0xFF23243A);
  static const inverseSurfaceDark = Color(0xFFE8EAF6);
}
