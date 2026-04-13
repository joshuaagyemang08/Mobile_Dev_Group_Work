// lib/core/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScribTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const primary = Color(0xFF5B4FE9);
  static const secondary = Color(0xFF00C9A7);
  static const error = Color(0xFFE95B5B);
  static const recording = Color(0xFFE95B5B);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const backgroundDark = Color(0xFF0F0F1A);
  static const surfaceDark = Color(0xFF1A1A2E);
  static const surfaceVariantDark = Color(0xFF252540);
  static const onSurfaceDark = Color(0xFFE8E8F0);
  static const textSecondaryDark = Color(0xFF8888AA);

  // ── Light palette ──────────────────────────────────────────────────────────
  static const backgroundLight = Color(0xFFF8F9FE);
  static const surfaceLight = Colors.white;
  static const surfaceVariantLight = Color(0xFFF1F3FB);
  static const onSurfaceLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF6E7191);

  // ── Aliases for dark mode (used throughout existing screens) ───────────────
  static const background = backgroundDark;
  static const surface = surfaceDark;
  static const surfaceVariant = surfaceVariantDark;
  static const onSurface = onSurfaceDark;
  static const textSecondary = textSecondaryDark;

  // ── Theme builders ─────────────────────────────────────────────────────────
  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? backgroundDark : backgroundLight;
    final sf = isDark ? surfaceDark : surfaceLight;
    final sfv = isDark ? surfaceVariantDark : surfaceVariantLight;
    final onSf = isDark ? onSurfaceDark : onSurfaceLight;
    final textSec = isDark ? textSecondaryDark : textSecondaryLight;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: sf,
        onSurface: onSf,
        surfaceContainerHighest: sfv,
        onSurfaceVariant: textSec,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.bold, color: onSf),
        titleLarge: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: onSf),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: onSf),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSec),
      ),
      cardTheme: CardThemeData(
        color: sf,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: onSf),
        titleTextStyle: TextStyle(
          color: onSf,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3)),
      ),
    );
  }
}
