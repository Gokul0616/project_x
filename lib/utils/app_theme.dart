import 'package:flutter/material.dart';

class AppTheme {
  // Classic Twitter Colors
  static const Color twitterBlue = Color(0xFF1DA1F2);
  static const Color darkBlue = Color(0xFF1A91DA);
  static const Color lightGray = Color(0xFFF7F9FA);
  static const Color darkGray = Color(0xFF657786);
  static const Color black = Color(0xFF14171A);
  static const Color white = Color(0xFFFFFFFF);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color darkCard = Color(0xFF1C1F23);
  static const Color darkBorder = Color(0xFF2F3336);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: twitterBlue,
    scaffoldBackgroundColor: white,
    cardColor: white,
    dividerColor: lightGray,
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      elevation: 1,
      iconTheme: IconThemeData(color: black),
      titleTextStyle: TextStyle(
        color: black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: black,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: darkGray,
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: twitterBlue,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: twitterBlue),
      ),
    ),
    iconTheme: const IconThemeData(color: black),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: twitterBlue,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 1,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: white,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF8B98A5),
        fontSize: 14,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: twitterBlue,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: twitterBlue),
      ),
      fillColor: darkSurface,
      filled: true,
    ),
    iconTheme: const IconThemeData(color: white),
  );
}