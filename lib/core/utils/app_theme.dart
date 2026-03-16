/// App Theme & Constants
/// Centralizes all color, typography, and spacing design tokens.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — deep electric teal
  static const Color primary = Color(0xFF00D4AA);
  static const Color primaryDark = Color(0xFF00A882);
  static const Color primaryLight = Color(0xFF4DFFCE);

  // Accent — vivid orange-amber
  static const Color accent = Color(0xFFFF6B2B);
  static const Color accentLight = Color(0xFFFF9A63);

  // Background (dark theme)
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF131929);
  static const Color bgCardLight = Color(0xFF1C2438);

  // Text
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textDisabled = Color(0xFF4A5568);

  // Status colors
  static const Color success = Color(0xFF00D4AA);
  static const Color warning = Color(0xFFFFBB00);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF4FC3F7);

  // Speedometer needle/gauge colors
  static const Color gaugeBackground = Color(0xFF1A2035);
  static const Color gaugeRing = Color(0xFF1E3045);
  static const Color gaugeLow = Color(0xFF00D4AA);
  static const Color gaugeMid = Color(0xFFFFBB00);
  static const Color gaugeHigh = Color(0xFFFF4757);

  // HUD mode
  static const Color hudGreen = Color(0xFF39FF14); // Neon green
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.bgCard,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        cardTheme: CardThemeData(
          color: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgCard,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.primary,
            fontSize: 72,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 48,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          labelLarge: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.bgDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryDark,
          secondary: AppColors.accent,
        ),
      );
}
