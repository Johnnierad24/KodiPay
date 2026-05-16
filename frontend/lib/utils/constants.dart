import 'package:flutter/material.dart';

class AppColors {
  static const Color kodiNavy = Color(0xFF002540);
  static const Color kodiBlue = Color(0xFF0047A1);
  static const Color kodiGreen = Color(0xFF009B61);
  static const Color kodiOrange = Color(0xFFF59E0B);
  static const Color darkNavy = Color(0xFF0B1736);
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFF64748B);
  static const Color muted = Color(0xFF94A3B8);
  static const Color white = Colors.white;
  static const Color danger = Color(0xFFEF4444);
  static const Color successSoft = Color(0xFFE7F8EF);
  static const Color warningSoft = Color(0xFFFFF7ED);
  static const Color dangerSoft = Color(0xFFFEE2E2);
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
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

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
}
