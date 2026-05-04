import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0D1B2A); // Dark blue from RN
  static const Color secondary = Color(0xFF00B4D8); // Accent
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFF94A3B8);
  static const Color brandBlue = Color(0xFF0F4C75);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: secondary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surfaceCard,
      surfaceVariant: surfaceVariant,
      outline: outline,
    ),
    scaffoldBackgroundColor: surfaceCard,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceCard,
      foregroundColor: primary,
      elevation: 0,
      centerTitle: false,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: secondary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      secondary: secondary,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
  );
}
