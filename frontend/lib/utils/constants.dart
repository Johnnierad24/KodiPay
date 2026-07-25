import 'package:flutter/material.dart';

class AppColors {
  // ── Brand (from Figma/Tailwind) ──────────────────────
  static const Color primary = Color(0xFF041627);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1A2B3C);
  static const Color onPrimaryContainer = Color(0xFF8192A7);
  static const Color primaryFixed = Color(0xFFD2E4FB);
  static const Color primaryFixedDim = Color(0xFFB7C8DE);
  static const Color inversePrimary = Color(0xFFB7C8DE);

  static const Color secondary = Color(0xFF5C5F61);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE0E3E5);
  static const Color onSecondaryContainer = Color(0xFF626567);

  static const Color tertiaryFixed = Color(0xFF6BFE9C);
  static const Color tertiaryFixedDim = Color(0xFF4AE183);
  static const Color tertiaryContainer = Color(0xFF003115);
  static const Color onTertiaryFixed = Color(0xFF00210C);
  static const Color onTertiaryFixedVariant = Color(0xFF005228);

  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color surfaceLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceHigh = Color(0xFFDCE9FF);
  static const Color surfaceHighest = Color(0xFFD3E4FE);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurfaceVariant = Color(0xFF44474C);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF74777D);
  static const Color outlineVariant = Color(0xFFC4C6CD);
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Legacy aliases (for compatibility) ─────────────
  static const Color kodiNavy = primary;
  static const Color kodiBlue = Color(0xFF0047A1);
  static const Color kodiGreen = Color(0xFF009B61);
  static const Color kodiOrange = Color(0xFFF59E0B);
  static const Color darkNavy = Color(0xFF0B1736);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = outlineVariant;
  static const Color divider = Color(0xFFE5E7EB);
  static const Color textDark = onBackground;
  static const Color textLight = onSurfaceVariant;
  static const Color muted = outline;
  static const Color white = Colors.white;

  // ── Status ─────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);
  static const Color successSoft = Color(0xFFE7F8EF);
  static const Color warningSoft = Color(0xFFFFF7ED);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color infoSoft = Color(0xFFEFF6FF);
}

class AppStyles {
  // Headline styles (Lexend family)
  static const TextStyle displayKsh = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02,
    height: 1.1,
    color: AppColors.primary,
  );
  static const TextStyle headlineLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.primary,
  );
  static const TextStyle headlineMd = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: AppColors.primary,
  );

  // Body styles (Inter family)
  static const TextStyle bodyLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.secondary,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.secondary,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.secondary,
  );

  // Label caps
  static const TextStyle labelCaps = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05,
    height: 1.33,
    color: AppColors.secondary,
  );

  // Legacy aliases
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, color: AppColors.textDark,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, color: AppColors.textDark,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, color: AppColors.textLight,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, color: AppColors.textLight,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textLight, letterSpacing: 1,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight,
  );
}

class Ui {
  static BorderRadius get radius => BorderRadius.circular(12);
  static BorderRadius get radiusSm => BorderRadius.circular(8);
  static BorderRadius get radiusLg => BorderRadius.circular(16);
  static BorderRadius get radiusXl => BorderRadius.circular(20);
  static BorderRadius get radius2xl => BorderRadius.circular(24);
  static const EdgeInsets pad = EdgeInsets.all(18);
  static const EdgeInsets padH = EdgeInsets.symmetric(horizontal: 18);
  static const EdgeInsets padV = EdgeInsets.symmetric(vertical: 18);

  static BoxDecoration card({
    Color? color,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: radius,
      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      boxShadow: elevated
          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]
          : null,
    );
  }

  static BoxDecoration statusBadge(Color bg, Color fg) {
    return BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999));
  }
}
