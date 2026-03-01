import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Colors.black;
  static const Color text = Colors.white;
  static const Color gold = Color(0xFFFFB000); // altın sarısı
  static const Color card = Color(0xFF111111);

  static ThemeData darkGold() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: gold,
        surface: card,
        onSurface: text,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
      ),
    );
  }
}
