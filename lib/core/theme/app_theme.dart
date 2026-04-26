import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extended color tokens not covered by Material 3 ColorScheme.
/// Access via `AppColors.primaryLight`, etc.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFB5674A); // Terracotta
  static const Color primaryLight = Color(0xFFC8856C);
  static const Color primaryDark = Color(0xFF924F37);
  static const Color primaryContainer = Color(0xFFF5EDE9);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color surfaceVariant = Color(0xFFEFEFEF);
  static const Color outline = Color(0xFFE5E5E5);

  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF9E9E9E);
  static const Color onPrimary = Color(0xFFFFFFFF);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Primary — Terracotta
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      // Secondary — neutral (reuse surface tones)
      secondary: AppColors.onSurfaceVariant,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.surfaceVariant,
      onSecondaryContainer: AppColors.onSurface,
      // Tertiary — unused, safe neutral
      tertiary: AppColors.onSurfaceVariant,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.surfaceVariant,
      onTertiaryContainer: AppColors.onSurface,
      // Error
      error: Color(0xFFB00020),
      onError: AppColors.onPrimary,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      // Surface
      surface: AppColors.background,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceVariant,
      surfaceContainerHigh: Color(0xFFE8E8E8),
      surfaceContainerHighest: AppColors.outline,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      // Outline
      outline: AppColors.outline,
      outlineVariant: AppColors.surfaceVariant,
      // Misc
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.onSurface,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.standard,

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // Typography
      textTheme: TextTheme(
        // Display — Playfair Display (editorial headings)
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: AppColors.onSurface,
        ),
        // Headline — Outfit (section / card titles)
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        // Title — Outfit
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        // Body — Noto Sans TC (Chinese-compatible)
        bodyLarge: GoogleFonts.notoSansTc(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.notoSansTc(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.notoSansTc(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        // Label — Outfit Uppercase (buttons, badges, nav)
        labelLarge: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.onSurface,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.onSurface,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}
