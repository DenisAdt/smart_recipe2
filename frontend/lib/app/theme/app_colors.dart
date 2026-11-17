import 'package:flutter/material.dart';

/// SRP Design System Color Palette
/// Based on Stitch-approved Material Design 3 warm earthy palette
class AppColors {
  AppColors._();

  // ── Light Theme ──────────────────────────────────────────────
  static const Color background = Color(0xFFFBF9F6);
  static const Color surface = Color(0xFFF5F3F0);          // surface-container-low
  static const Color surfaceContainer = Color(0xFFEFEEEB); // surface-container
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // cards
  static const Color surfaceVariant = Color(0xFFE4E2DF);   // borders/separators
  static const Color border = Color(0xFFE9E2DA);           // card borders

  static const Color textPrimary = Color(0xFF1B1C1A);      // on-background
  static const Color textSecondary = Color(0xFF444840);    // on-surface-variant
  static const Color textTertiary = Color(0xFF75786F);     // outline

  // ── Dark Theme ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF131312);
  static const Color darkSurface = Color(0xFF1E1F1D);
  static const Color darkSurface2 = Color(0xFF2A2C29);
  static const Color darkBorder = Color(0xFF3A3C39);

  static const Color darkTextPrimary = Color(0xFFE4E2DF);
  static const Color darkTextSecondary = Color(0xFFBDBFC0);
  static const Color darkTextTertiary = Color(0xFF8A8D87);

  // ── Primary (Forest Green) ─────────────────────────────────────
  static const Color primary = Color(0xFF46573B);            // primary
  static const Color onPrimary = Color(0xFFFFFFFF);          // on-primary
  static const Color primaryContainer = Color(0xFF5E6F52);   // primary-container
  static const Color onPrimaryContainer = Color(0xFFDEF1CD); // on-primary-container
  static const Color primaryFixed = Color(0xFFBACCAA);       // primary-fixed
  static const Color primaryFixedDim = Color(0xFFBACCAA);    // primary-fixed-dim
  static const Color inversePrimary = Color(0xFFBACCAA);     // inverse-primary

  // ── Secondary (Warm Amber) ─────────────────────────────────────
  static const Color secondary = Color(0xFF7E5700);          // secondary
  static const Color onSecondary = Color(0xFFFFFFFF);        // on-secondary
  static const Color secondaryContainer = Color(0xFFFEC668); // secondary-container
  static const Color onSecondaryContainer = Color(0xFF765100); // on-secondary-container

  // ── Tertiary (Terracotta) ──────────────────────────────────────
  static const Color tertiary = Color(0xFF823F20);           // tertiary
  static const Color onTertiary = Color(0xFFFFFFFF);         // on-tertiary
  static const Color tertiaryContainer = Color(0xFFA05636);  // tertiary-container

  // ── Surface / Inverse ─────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF30312F);      // inverse-surface
  static const Color inverseOnSurface = Color(0xFFF2F0ED);    // inverse-on-surface

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF34A853);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFFEC668);

  // ── Input / Chip fill ─────────────────────────────────────────
  static const Color inputFill = Color(0xFFF2EEE9);          // #F2EEE9

  // ── Legacy aliases (used in existing widgets) ─────────────────
  // These map old names to new colors so we don't break other files
  static const Color accentBlue = primary;                   // was blue, now primary green
  static const Color accentPurple = primaryContainer;        // was purple
  static const Color accentViolet = secondaryContainer;      // was violet

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surfaceContainer],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceContainerLowest, surface],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkSurface, darkSurface2],
  );

  // ── Chip colors (legacy compat) ───────────────────────────────
  static const Color chipBlue = Color(0xFFD5E9C5);           // primary-fixed
  static const Color chipBlueDark = Color(0xFF3B4B31);       // on-primary-fixed-variant

  // ── Score badges ─────────────────────────────────────────────
  static const Color star5 = primary;
  static const Color star4 = Color(0xFF34A853);
  static const Color star3 = Color(0xFFFBBC04);
  static const Color star2 = Color(0xFFFF6D00);
  static const Color star1 = error;

  // ── Category colors ───────────────────────────────────────────
  static const Color goreng = Color(0xFFA05636);   // tertiary-container
  static const Color rebus = primary;
  static const Color tumis = Color(0xFF34A853);
  static const Color panggang = Color(0xFF823F20); // tertiary

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'goreng':
        return goreng;
      case 'rebus':
        return rebus;
      case 'tumis':
        return tumis;
      case 'panggang':
        return panggang;
      default:
        return primaryContainer;
    }
  }
}
