// lib/core/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScribTheme {
  // Brand colours
  static const primary = Color(0xFF5B4FE9);       // Indigo-purple
  static const secondary = Color(0xFF00C9A7);      // Mint
  static const background = Color(0xFF0F0F1A);     // Near-black
  static const surface = Color(0xFF1A1A2E);        // Dark navy
  static const surfaceVariant = Color(0xFF252540);
  static const onSurface = Color(0xFFE8E8F0);
  static const textSecondary = Color(0xFF8888AA);
  static const error = Color(0xFFE95B5B);
  static const recording = Color(0xFFE95B5B);      // Red for record button

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: onSurface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
              fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
          titleLarge: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
          bodyMedium:
              GoogleFonts.inter(fontSize: 14, color: onSurface),
          bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
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