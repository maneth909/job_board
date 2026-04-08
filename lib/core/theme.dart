import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light Mode Colors
const _lightPrimary = Color(0xFF0C36FA);
const _lightBackground = Color(0xFFFFFFFF);
const _lightSecondary = Color(0xFFF4F4F5);
const _lightTextBlack = Color(0xFF09090B);
const _lightMuted = Color(0xFF71717A);
const _lightBorder = Color(0xFFE4E4E7);
const _lightError = Color(0xFFEF4444);

// Dark Mode Colors
const _darkPrimary = Color(0xFF60A5FA);
const _darkBackground = Color(0xFF272729);
const _darkSecondary = Color(0xFF18181B);
const _darkTextForeground = Color(0xFFFAFAFA);
const _darkMuted = Color(0xFFA1A1AA);
const _darkBorder = Color(0xFF38383F);
const _darkError = Color(0xFFF87171);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: _lightPrimary,
    surface: _lightBackground,
    secondary: _lightSecondary,
    onSurface: _lightTextBlack,
    error: _lightError,
    outline: _lightBorder,
    onSecondary: _lightTextBlack,
    primaryContainer: _lightPrimary,
    onPrimary: Colors.white,
    onPrimaryContainer: Colors.white,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: _lightBackground,
  dividerColor: _lightBorder,
  textTheme: GoogleFonts.interTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: _lightTextBlack),
      bodyMedium: TextStyle(color: _lightTextBlack),
      bodySmall: TextStyle(color: _lightMuted),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _lightBackground,
    foregroundColor: _lightTextBlack,
    elevation: 0,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _darkPrimary,
    surface: _darkBackground,
    secondary: _darkSecondary,
    onSurface: _darkTextForeground,
    error: _darkError,
    outline: _darkBorder,
    onSecondary: _darkTextForeground,
    primaryContainer: _darkPrimary,
    onPrimary: _darkTextForeground,
    onPrimaryContainer: _darkTextForeground,
    onError: _darkTextForeground,
  ),
  scaffoldBackgroundColor: _darkBackground,
  dividerColor: _darkBorder,
  textTheme: GoogleFonts.interTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: _darkTextForeground),
      bodyMedium: TextStyle(color: _darkTextForeground),
      bodySmall: TextStyle(color: _darkMuted),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _darkBackground,
    foregroundColor: _darkTextForeground,
    elevation: 0,
  ),
);
