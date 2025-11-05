import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

class AppTheme {
  // Couleurs
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color errorColor = AppColors.error;
  static const Color onPrimary = AppColors.onPrimary;
  static const Color onSecondary = AppColors.onSecondary;
  static const Color onBackground = AppColors.onBackground;
  static const Color onSurface = AppColors.onSurface;
  static const Color onError = AppColors.onError;

  // Dimensions
  static const double smallPadding = AppDimens.small;
  static const double mediumPadding = AppDimens.medium;
  static const double largePadding = AppDimens.large;
  static const double extraLargePadding = AppDimens.extraLarge;

  // Textes
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: onBackground,
    ),
    displayMedium: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: onBackground,
    ),
    titleLarge: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: onBackground,
    ),
    bodyLarge: TextStyle(
      fontSize: 16.0,
      color: onBackground,
    ),
    bodyMedium: TextStyle(
      fontSize: 14.0,
      color: onSurface,
    ),
  );

  // Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onBackground: onBackground,
      onSurface: onSurface,
      onError: onError,
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: onPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: largePadding,
          vertical: mediumPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: mediumPadding,
        vertical: smallPadding,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.all(mediumPadding),
    ),
  );

  // Thème sombre (optionnel)
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      error: errorColor,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onBackground: Colors.white,
      onSurface: Colors.white,
      onError: onError,
    ),
    textTheme: textTheme.copyWith(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white70),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );

  // Méthode utilitaire pour obtenir le thème actuel
  static ThemeMode getThemeMode(String themeMode) {
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
