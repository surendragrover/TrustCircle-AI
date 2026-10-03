import 'package:flutter/material.dart';

abstract final class TrustCircleColors {
  static const trustNavy = Color(0xFF0B1F33);
  static const trustBlue = Color(0xFF1E5AA8);
  static const intelligenceTeal = Color(0xFF0F8B8D);
  static const background = Color(0xFFF4F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const secondarySurface = Color(0xFFEAF0F6);
  static const textPrimary = Color(0xFF17202A);
  static const textSecondary = Color(0xFF5B6773);
  static const border = Color(0xFFD7E0E8);
  static const success = Color(0xFF16805C);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFC0392B);
  static const neutral = Color(0xFF667085);

  static const verdicts = <String, Color>{
    'trustworthy': Color(0xFF16805C),
    'mostlyTrustworthy': Color(0xFF2F855A),
    'suspicious': Color(0xFFB7791F),
    'notTrustworthy': Color(0xFFC05621),
    'deceptive': Color(0xFFC0392B),
    'inconclusive': neutral,
  };
}

abstract final class TrustCircleSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class TrustCircleTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: TrustCircleColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TrustCircleColors.trustBlue,
      brightness: Brightness.light,
      primary: TrustCircleColors.trustBlue,
      secondary: TrustCircleColors.intelligenceTeal,
      surface: TrustCircleColors.surface,
      error: TrustCircleColors.danger,
      onPrimary: Colors.white,
      onSurface: TrustCircleColors.textPrimary,
    ),
    textTheme: ThemeData.light().textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: TrustCircleColors.trustNavy,
        letterSpacing: 0,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: TrustCircleColors.trustNavy,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: TrustCircleColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 15,
        color: TrustCircleColors.textPrimary,
        height: 1.45,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: TrustCircleColors.textSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TrustCircleColors.trustNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: TrustCircleColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TrustCircleColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TrustCircleColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: TrustCircleColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: TrustCircleColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: TrustCircleColors.trustBlue,
          width: 2,
        ),
      ),
      labelStyle: const TextStyle(color: TrustCircleColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TrustCircleColors.trustBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TrustCircleColors.trustBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TrustCircleColors.trustBlue,
        minimumSize: const Size(44, 46),
        side: const BorderSide(color: TrustCircleColors.trustBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: TrustCircleColors.trustNavy,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TrustCircleColors.surface,
      indicatorColor: TrustCircleColors.secondarySurface,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
