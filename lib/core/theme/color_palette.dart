import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF202327);
  static const Color midGray = Color(0xFF536471);
  static const Color lightGray = Color(0xFFD6D9DB);
  
  // Accent color (Twitter-like blue)
  static const Color blue = Color(0xFF1D9BF0);
  static const Color blueHighlight = Color(0xFF1A8CD8);
  static const Color blueDisabled = Color(0x801D9BF0); // 50% opacity = 0x80
  
  // Background colors
  static const Color backgroundColor = black;
  static const Color surfaceColor = Color(0xFF15181C);
  static const Color cardColor = Color(0xFF202327);
  
  // Feedback colors
  static const Color success = Color(0xFF00CB6A);
  static const Color error = Color(0xFFF91880);
  static const Color warning = Color(0xFFF7B955);
  static const Color info = Color(0xFF1D9BF0);
  
  // Text colors
  static const Color textPrimary = white;
  static const Color textSecondary = midGray;
  static const Color textDisabled = Color(0x80536471); // 50% opacity
  
  // Border colors
  static const Color borderColor = Color(0xFF2F3336);
  
  // Overlay colors
  static const Color overlay = Color(0x6615181C); // Already using alpha = 0x66
}
