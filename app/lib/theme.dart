import "package:flutter/material.dart";

const Color brandColor = Color(0xFF64A7FF);

const Color darkBackgroundColor = Color(0xFF1A2433);
const Color darkCardColor = Color(0xFF252B3B);

const Color lightBackgroundColor = Color(0xFFF5F7FA);
const Color lightCardColor = Color(0xFFFFFFFF);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: lightBackgroundColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: Brightness.light,
    surface: lightCardColor,
    onSurface: Color(0xFF1A2433),
  ).copyWith(primary: brandColor),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A2433),
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A2433),
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A2433),
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1A2433),
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A2433),
    ),
    bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF1A2433)),
    bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF1A2433)),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: darkBackgroundColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: Brightness.dark,
    surface: darkCardColor,
    onSurface: Colors.white,
  ).copyWith(primary: brandColor),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE0E0E0),
    ),
    bodyLarge: TextStyle(fontSize: 18, color: Color(0xFFE0E0E0)),
    bodyMedium: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
  ),
);
