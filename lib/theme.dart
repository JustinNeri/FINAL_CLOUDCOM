import 'package:flutter/material.dart';

class ThemeColors {
  static const Color deepNavy = Color(0xFF101423);
  static const Color cardNavy = Color(0xFF1C233E);
  static const Color borderNavy = Color(0xFF22344A);
  static const Color pokeYellow = Color(0xFFFFCB05);
  static const Color pokeRed = Color(0xFFEE1515);
  static const Color pokeBlue = Color(0xFF1A73E8);
  static const Color accentMuted = Color(0xFFA0AEC0);
  static const Color success = Color(0xFF1E9E5A);

  static const Color background = Color(0xFFF4F6FB);
  static const Color outline = Color(0xFFDDE3EE);
  static const Color textMuted = Color(0xFF5B6478);
}

class AppTheme {
  static const double radius = 16;

  /// Widest the content column grows on tablets and desktop browsers.
  static const double maxContentWidth = 720;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ThemeColors.pokeBlue,
      primary: ThemeColors.pokeBlue,
      onPrimary: Colors.white,
      secondary: ThemeColors.pokeYellow,
      onSecondary: ThemeColors.deepNavy,
      tertiary: ThemeColors.pokeRed,
      onTertiary: Colors.white,
      error: const Color(0xFFD32F2F),
      surface: Colors.white,
      onSurface: ThemeColors.deepNavy,
    );
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    // Start from Material's platform text theme so custom styles keep its font.
    final textTheme = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
    final buttonText = textTheme.labelLarge!.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ThemeColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge!.copyWith(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: ThemeColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded,
          textStyle: buttonText,
          side: const BorderSide(color: ThemeColors.outline, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: buttonText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ThemeColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ThemeColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ThemeColors.pokeBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ThemeColors.deepNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      listTileTheme: const ListTileThemeData(iconColor: ThemeColors.textMuted),
      dividerTheme: const DividerThemeData(color: ThemeColors.outline, space: 1),
    );
  }
}
