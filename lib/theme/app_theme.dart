import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF141218);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color accentPurple = Color(0xFF9191D5);
  static const Color incomeGreen = Color(0xFF2E7D32);
  static const Color expenseRed = Color(0xFFD32F2F);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF949494);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: ColorScheme.dark(
      primary: accentPurple,
      surface: surfaceDark,
      onSurface: textWhite,
      secondary: accentPurple,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2B2930),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: textGrey),
    ),
  );

  static const TextStyle balanceLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: textWhite,
  );

  static const TextStyle labelMedium = TextStyle(fontSize: 14, color: textGrey);

  static const TextStyle amountMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}
