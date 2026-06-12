import 'package:flutter/material.dart';

class AppColors {
  // Primary — blue gradient (dashboard header)
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryBlueDark = Color(0xFF1565C0);
  static const Color primaryBlueMid = Color(0xFF1E88E5);

  // Accent — purple (top bars, FAB, chips)
  static const Color accent = Color(0xFF6B8AFF);
  static const Color accentDark = Color(0xFF0D47A1);

  // Status
  static const Color statusPassed = Color(0xFF00C853);
  static const Color statusGreen = Color(0xFF00E676);
  static const Color statusFailed = Color(0xFFEF5350);
  static const Color statusPending = Color(0xFFFFAB00);
  static const Color statusLoading = Color(0xFF6B8AFF);
  static const Color statusOrange = Color(0xFFFF9800);

  // Background
  static const Color scaffoldBg = Color(0xFFF7F9FA);
  static const Color cardBg = Color(0xFFF5F5F5);
  static const Color white = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Colors.grey;

  // Trip card backgrounds
  static const Color tripCompletedBg = Color(0xFFE8F6EF);
  static const Color tripPendingBg = Color(0xFFFFF7E6);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
      );
}
