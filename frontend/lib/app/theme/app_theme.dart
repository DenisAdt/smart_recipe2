import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _radius = 16.0;
  static const _radiusLarge = 12.0;

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      // headline-lg: 32px / 600
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 1.25,
        letterSpacing: -0.02 * 32,
      ),
      // headline-md: 24px / 600
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.33,
        letterSpacing: -0.01 * 24,
      ),
      // headline-sm: 20px / 600
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.4,
      ),
      // title uses headline-sm style
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      // body-lg: 18px / 400
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontSize: 18,
        height: 1.55,
      ),
      // body-md: 16px / 400
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: secondary,
        fontSize: 16,
        height: 1.5,
      ),
      // body-sm / label-md: 14px
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: secondary,
        fontSize: 14,
        height: 1.43,
      ),
      // label-md: 14px / 500
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: primary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.01 * 14,
      ),
      // label-sm: 12px / 600 / tracked
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: secondary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.05 * 12,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: GoogleFonts.inter().fontFamily,
        color: secondary,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    );
  }

  // ── LIGHT THEME ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiary,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      surfaceContainerHigh: AppColors.surfaceContainer,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerLow: AppColors.surface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textTertiary,
      outlineVariant: AppColors.surfaceVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.inputFill,
        selectedColor: AppColors.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  // ── DARK THEME ───────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryFixed,
      onPrimary: AppColors.inverseSurface,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondaryContainer,
      onSecondary: AppColors.inverseSurface,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.onSecondary,
      tertiary: AppColors.primaryFixed,
      onTertiary: AppColors.inverseSurface,
      tertiaryContainer: AppColors.tertiary,
      onTertiaryContainer: AppColors.onTertiary,
      error: AppColors.errorContainer,
      onError: AppColors.error,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.errorContainer,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkBorder,
      surfaceContainerHigh: AppColors.darkSurface2,
      surfaceContainer: AppColors.darkSurface2,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainerLowest: AppColors.darkBackground,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkTextTertiary,
      outlineVariant: AppColors.darkBorder,
      inverseSurface: AppColors.darkTextPrimary,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.primary,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppColors.primaryFixed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          borderSide: const BorderSide(color: AppColors.primaryFixed, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.darkTextTertiary,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryFixed,
          foregroundColor: AppColors.inverseSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface2,
        selectedColor: AppColors.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
