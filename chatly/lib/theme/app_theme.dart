import 'package:flutter/material.dart';

/// Marka paleti
/// primary        : 0xFF2F4156
/// secondary      : 0xFF567C8D
/// surfaceVariant : 0xFFC8D9E6
/// light background: 0xFFF5EFEB
class AppTheme {
  // Brand colors
  static const Color brandPrimary = Color(0xFF2F4156);
  static const Color brandSecondary = Color(0xFF567C8D);
  static const Color brandSurfaceVariantLight = Color(0xFFC8D9E6);
  static const Color brandBackgroundLight = Color(0xFFF5EFEB);
  static const Color brandwhite = Colors.white;
  static const Color brandtype = Color.fromARGB(255, 220, 220, 220);
  static const Color brandblack = Colors.black45;

  // Dark güvenli zeminler
  static const Color brandBackgroundDark = Color(0xFF121212);
  static const Color brandSurfaceVariantDark = Color(0xFF2B3A44);

  static ThemeData get light => _buildLightTheme();
  static ThemeData get dark => _buildDarkTheme();

  // -------------------- LIGHT THEME --------------------
  static ThemeData _buildLightTheme() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: brandPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: brandPrimary,
          secondary: brandSecondary,
          surfaceVariant: brandSurfaceVariantLight,
          background: brandBackgroundLight,
          scrim: brandtype,
          tertiary: brandSurfaceVariantLight,
          shadow: brandSecondary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
        centerTitle: true,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: brandBackgroundLight,
        selectedItemColor: Color(0xFFC8D9E6),
        unselectedItemColor: Color(0xFF7A7A7A),
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        type: BottomNavigationBarType.fixed,
      ),

      cardTheme: CardThemeData(
        // <-- DÜZELTİLDİ
        color: scheme.surface,
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // -------------------- DARK THEME --------------------
  static ThemeData _buildDarkTheme() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: brandPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: brandwhite,
          secondary: brandSecondary,
          surfaceVariant: brandSurfaceVariantDark,
          background: brandBackgroundDark,
          scrim: brandblack,
          tertiary: brandSurfaceVariantDark,
          shadow: brandSurfaceVariantLight,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
        centerTitle: true,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.secondary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.background,
        selectedItemColor: scheme.secondary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
