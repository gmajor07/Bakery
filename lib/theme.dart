import 'package:flutter/material.dart';

class AppTheme {
  // Professional Bakery Palette
  // Using warm, sophisticated tones: Cream, Rich Espresso, and Soft Gold
  static const Color primaryBrown = Color(0xFF5D4037); // Rich Espresso
  static const Color secondaryGold = Color(0xFFD4A373); // Warm Crust
  static const Color backgroundLight = Color(0xFFF6EFE7); // Warm ivory
  static const Color surfaceLight = Color(0xFFFFFAF4); // Premium soft surface

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF12100E);
  static const Color surfaceDark = Color(0xFF1C1917);
  static const Color primaryBrownDark = Color(0xFFBCAAA4);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryBrown,
        secondary: secondaryGold,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSurface: const Color(0xFF2D1B16), // Deepest brown for text
        outlineVariant: const Color(0xFFE8DCD2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF2D1B16)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D1B16),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2D1B16),
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D1B16),
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFEDE2D8), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBrown,
          side: const BorderSide(color: primaryBrown),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: primaryBrownDark,
        secondary: secondaryGold,
        surface: surfaceDark,
        onPrimary: Colors.black,
        onSurface: Colors.white.withValues(alpha: 0.9),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrownDark,
          foregroundColor: Colors.black, // High contrast text for visibility
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBrownDark,
          side: const BorderSide(color: primaryBrownDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBrownDark,
        ),
      ),
    );
  }
}
