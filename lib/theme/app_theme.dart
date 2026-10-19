import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF121118);
  static const Color surfaceDark = Color(0xFF1B1A23);
  static const Color cardDark = Color(0xFF22212E);
  static const Color accentPurple = Color(0xFF8B80F9);
  static const Color accentCyan = Color(0xFF38EF7D);
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color expenseRed = Color(0xFFF43F5E);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF9CA3AF);

  static const String currencySymbol = '৳';

  /// Formats amount as integer with BDT symbol, e.g. ৳10, ৳1,500
  static String formatAmount(num amount) {
    final rounded = amount.round();
    final formatted = NumberFormat('#,###').format(rounded.abs());
    if (rounded < 0) {
      return '-৳$formatted';
    }
    return '৳$formatted';
  }

  /// Formats signed amount e.g. - ৳150, + ৳500
  static String formatSignedAmount(num amount, {required bool isExpense, bool isIncome = false}) {
    final rounded = amount.round().abs();
    final formatted = NumberFormat('#,###').format(rounded);
    if (isExpense) {
      return '- ৳$formatted';
    } else if (isIncome) {
      return '+ ৳$formatted';
    }
    return '৳$formatted';
  }

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: const ColorScheme.dark(
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentPurple,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF262533),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: textGrey, fontSize: 14),
    ),
  );

  static const TextStyle balanceLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textWhite,
    letterSpacing: -0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    color: textGrey,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
