import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────

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

  static const Color error = Color(0xFFB00020);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
}

// ─── Spacing Tokens ───────────────────────────────────────────────────────────

/// 8px-grid spacing tokens. Use `AppSpacing.md` instead of magic numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─── Border Radius Tokens ─────────────────────────────────────────────────────

/// Unified border radius constants. Use `AppRadius.card`, etc.
class AppRadius {
  AppRadius._();

  static const double card = 12;
  static const double button = 8;
  static const double input = 10;
  static const double dialog = 16;
  static const double sheet = 20; // top corners of bottom sheets
  static const double icon = 10;
  static const double pill = 100; // tags / filter chips

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius inputAll = BorderRadius.all(Radius.circular(input));
  static const BorderRadius dialogAll = BorderRadius.all(Radius.circular(dialog));
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

// ─── Theme ────────────────────────────────────────────────────────────────────

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
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
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

    // Shared button style helpers
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.buttonAll);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm + 4, // 12px vertical
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      visualDensity: VisualDensity.standard,

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      // Spec: radius 12px, 1px outline border, no shadow
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: AppColors.outline),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      // Primary: filled Terracotta, white label, radius 8px
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      // Secondary: transparent bg, charcoal border + text, radius 8px
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.onSurface, width: 1.5),
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      // Ghost/Tonal: primaryContainer bg, Terracotta text, radius 8px
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.primary,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ── Input ────────────────────────────────────────────────────────────
      // Spec: outlined style, 1.5px border, radius 10px, focus → onSurface
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4, // 12px
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: AppColors.outline, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: AppColors.outline, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: AppColors.onSurface, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.notoSansTc(
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      // Spec: white bg, top border 1px outline, Terracotta active, no pill
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: Colors.transparent, // disable M3 pill indicator
        shadowColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((final states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((final states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // ── Typography ───────────────────────────────────────────────────────
      textTheme: TextTheme(
        // Display — Playfair Display (editorial headings)
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        // Headline — Outfit (section / card titles)
        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        // Title — Outfit
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        // Body — Noto Sans TC (Chinese-compatible)
        bodyLarge: GoogleFonts.notoSansTc(
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.notoSansTc(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.notoSansTc(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        // Label — Outfit Uppercase (buttons, badges, nav)
        labelLarge: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
