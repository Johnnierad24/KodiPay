import 'package:flutter/material.dart';

class AppColors {
  static const Color kodiBlue = Color(0xFF004AAD);
  static const Color kodiOrange = Color(0xFFFF5733);
  static const Color darkNavy = Color(0xFF0A192F);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF757575);
  static const Color white = Colors.white;
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );
}
