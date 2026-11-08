import 'package:flutter/material.dart';

class AppColors {
  // Primary (Deep Slate Navy #1E293B) & Accent (Amber #F59E0B)
  static const Color primary = Color(0xFF1E293B); // Deep Slate Navy
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color accent = Color(0xFFF59E0B);  // Amber
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFFFBEB); // Amber tint for cards/answers

  // Backward-compatibility alias
  static const Color primaryLight = Color(0xFFFFFBEB);

  // Dark Auth & Owl Backgrounds
  static const Color backgroundDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceDark = Color(0xFF26364F);     // Dark card surface
  static const Color cardDarkElevated = Color(0xFF334155); // Slate 700 chips / bubbles

  // Light Dashboard Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);    // White cards
  static const Color surfaceMuted = Color(0xFFF1F5F9);    // Slate 100 input / pills
  static const Color bannerBackground = Color(0xFFE2E8F0); // Mascot banner background

  // Text Colors
  static const Color textDark = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLightMuted = Color(0xFFCBD5E1);

  // Status & Priority Accents
  static const Color success = Color(0xFF10B981); // Emerald green (streak, high priority, online)
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);

  // Border & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
}
