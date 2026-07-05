import 'package:flutter/material.dart';

class AppTheme {
  static const _lightBackground = Color(0xFFF7FAFC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightPrimary = Color(0xFF0B5FFF);
  static const _lightSecondary = Color(0xFF00A6A6);
  static const _lightText = Color(0xFF101828);

  static const _darkBackground = Color(0xFF080D18);
  static const _darkSurface = Color(0xFF111827);
  static const _darkPrimary = Color(0xFF5B8CFF);
  static const _darkSecondary = Color(0xFF22D3EE);
  static const _darkText = Color(0xFFF8FAFC);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _lightPrimary,
      brightness: Brightness.light,
      primary: _lightPrimary,
      secondary: _lightSecondary,
      surface: _lightSurface,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _textTheme(_lightText),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _darkPrimary,
      brightness: Brightness.dark,
      primary: _darkPrimary,
      secondary: _darkSecondary,
      surface: _darkSurface,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _textTheme(_darkText),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        backgroundColor: scheme.surfaceContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      headlineLarge: TextStyle(
        color: color,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(color: color, fontSize: 16, letterSpacing: 0),
      bodyMedium: TextStyle(color: color.withValues(alpha: 0.78), fontSize: 14),
      labelLarge: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}
