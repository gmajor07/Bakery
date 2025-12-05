import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color primaryBrown = Color(
    0xFFA66F2B,
  ); // Primary color is the same
  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // Dark Theme Colors
  // We'll use a deep, dark grey for the background and surface for an authentic dark mode feel.
  // Dark theme colors should be consistent with Material Design guidelines.
  static const Color backgroundDark = Color(0xFF121212); // Deep dark grey
  static const Color surfaceDark = Color(
    0xFF1E1E1E,
  ); // Slightly lighter than background for elevation
  static const Color onSurfaceDark =
      Colors.white70; // Text color on dark surfaces
  static const Color primaryBrownDark = Color(
    0xFFD7A76D,
  ); // A lighter shade of brown for contrast (or keep primaryBrown if preferred)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryBrown,
        surface: surfaceLight,
        background: backgroundLight,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelStyle: const TextStyle(color: primaryBrown),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: ThemeData.light().textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // --- Dark Theme Implementation ---

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        // Use a lighter brown for better contrast on a dark background
        primary: primaryBrownDark,
        surface: surfaceDark,
        background: backgroundDark,
        onPrimary: Colors.black, // Text color on the primary brown
        onSurface: onSurfaceDark,
        onBackground: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        // Make the text/icons white on the dark AppBar
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primaryBrownDark, // Use the primary color
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ), // Light text on dark background
        labelLarge: ThemeData.dark().textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark, // Use the slightly lighter dark surface
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        // Use a very light grey for borders in dark mode
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: primaryBrownDark,
            width: 2,
          ), // Use the lighter brown
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ), // Bright red for error
        ),
        labelStyle: const TextStyle(color: Colors.white54),
        floatingLabelStyle: const TextStyle(color: primaryBrownDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrownDark, // Use the lighter brown
          foregroundColor:
              Colors.black, // Dark text on the lighter brown button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: ThemeData.dark().textTheme.labelLarge?.copyWith(
            color: Colors.black,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: primaryBrownDark, // Outline color
          side: const BorderSide(color: primaryBrownDark),
        ),
      ),
    );
  }
}
