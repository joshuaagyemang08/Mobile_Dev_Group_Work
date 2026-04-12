// lib/core/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScribTheme {
  // Brand colours
  static const primary = Color(0xFF5B4FE9);       // Indigo-purple
  static const secondary = Color(0xFF00C9A7);      // Mint
  
  // Dark Palette
  static const backgroundDark = Color(0xFF0F0F1A);     // Near-black
  static const surfaceDark = Color(0xFF1A1A2E);        // Dark navy
  static const surfaceVariantDark = Color(0xFF252540);
  static const onSurfaceDark = Color(0xFFE8E8F0);
  static const textSecondaryDark = Color(0xFF8888AA);
  
  // Light Palette
  static const backgroundLight = Color(0xFFF8F9FE);
  static const surfaceLight = Colors.white;
  static const surfaceVariantLight = Color(0xFFF1F3FB);
  static const onSurfaceLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF6E7191);

  static const error = Color(0xFFE95B5B);
  static const recording = Color(0xFFE95B5B);

  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? backgroundDark : backgroundLight;
    final surface = isDark ? surfaceDark : surfaceLight;
    final onSurface = isDark ? onSurfaceDark : onSurfaceLight;
    final textSecondary = isDark ? textSecondaryDark : textSecondaryLight;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        // Using surface for background/onBackground as well for consistency
        surfaceContainer: surface,
        onSurfaceVariant: textSecondary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
        titleLarge: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: onSurface),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  // Fallback static values for components not yet using Theme.of(context)
  static const background = backgroundDark;
  static const surface = surfaceDark;
  static const surfaceVariant = surfaceVariantDark;
  static const onSurface = onSurfaceDark;
  static const textSecondary = textSecondaryDark;
}