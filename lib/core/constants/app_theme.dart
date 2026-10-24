import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design system dials: ENERGY 2 / RHYTHM 2 / MOTION 2
// Palette: Vintage editorial — cream base, deep black text, ember-orange accent

class AppColors {
  AppColors._();

  // Base
  static const cream = Color(0xFFF5F0E8);
  static const parchment = Color(0xFFEDE6D6);
  static const warmWhite = Color(0xFFFAF7F2);

  // Text
  static const inkBlack = Color(0xFF1A1A1A);
  static const charcoal = Color(0xFF2D2D2D);
  static const warmGrey = Color(0xFF6B6560);
  static const mutedGrey = Color(0xFF9E9790);

  // Accent
  static const ember = Color(0xFFC4622D);
  static const emberLight = Color(0xFFD4724D);
  static const emberDark = Color(0xFFAA4E22);

  // Borders and dividers
  static const borderLight = Color(0xFFE0D8CC);
  static const borderMedium = Color(0xFFCCC2B2);

  // Status
  static const success = Color(0xFF4A7C59);
  static const error = Color(0xFFB94040);
  static const warning = Color(0xFFB8860B);

  // Condition badge backgrounds (muted, editorial)
  static const conditionNew = Color(0xFFEAF0E8);
  static const conditionLikeNew = Color(0xFFE8EDF0);
  static const conditionGood = Color(0xFFF0EDE8);
  static const conditionFair = Color(0xFFF0ECE0);
  static const conditionSalvage = Color(0xFFF0E8E8);
}

class AppTypography {
  AppTypography._();

  // Playfair Display for editorial headings — conveys vintage, curated character
  // Inter for body — clean legibility without competing with headings

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 40, fontWeight: FontWeight.w700, height: 1.1,
        color: AppColors.inkBlack, letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 32, fontWeight: FontWeight.w600, height: 1.15,
        color: AppColors.inkBlack, letterSpacing: -0.3,
      );

  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
        fontSize: 26, fontWeight: FontWeight.w600, height: 1.2,
        color: AppColors.inkBlack,
      );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.w500, height: 1.25,
        color: AppColors.inkBlack,
      );

  static TextStyle get headlineSmall => GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.w500, height: 1.3,
        color: AppColors.inkBlack,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, height: 1.4,
        color: AppColors.inkBlack,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
        color: AppColors.inkBlack, letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, height: 1.6,
        color: AppColors.charcoal,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
        color: AppColors.charcoal,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.5,
        color: AppColors.warmGrey,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.3,
        color: AppColors.inkBlack, letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, height: 1.3,
        color: AppColors.warmGrey, letterSpacing: 0.8,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, height: 1.3,
        color: AppColors.mutedGrey, letterSpacing: 0.5,
      );

  static TextStyle get captionText => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w400, height: 1.4,
        color: AppColors.warmGrey,
      );

  static TextStyle get priceText => GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w700, height: 1.2,
        color: AppColors.inkBlack,
      );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppRadius {
  AppRadius._();

  static const double small = 4;
  static const double medium = 8;
  static const double large = 12;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(small));
  static const BorderRadius md = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(large));
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.ember,
        onPrimary: AppColors.warmWhite,
        primaryContainer: Color(0xFFF4DDD3),
        onPrimaryContainer: AppColors.emberDark,
        secondary: AppColors.inkBlack,
        onSecondary: AppColors.warmWhite,
        secondaryContainer: AppColors.parchment,
        onSecondaryContainer: AppColors.charcoal,
        tertiary: AppColors.warmGrey,
        onTertiary: AppColors.warmWhite,
        tertiaryContainer: AppColors.cream,
        onTertiaryContainer: AppColors.charcoal,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFFF9DEDE),
        onErrorContainer: AppColors.error,
        surface: AppColors.warmWhite,
        onSurface: AppColors.inkBlack,
        surfaceContainerHighest: AppColors.parchment,
        onSurfaceVariant: AppColors.charcoal,
        outline: AppColors.borderMedium,
        outlineVariant: AppColors.borderLight,
        inverseSurface: AppColors.inkBlack,
        onInverseSurface: AppColors.cream,
        inversePrimary: AppColors.emberLight,
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.warmWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.inkBlack,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.borderLight,
        titleTextStyle: AppTypography.titleLarge,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.inkBlack, size: 22),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.warmWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.ember, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.mutedGrey),
        labelStyle: AppTypography.bodyMedium,
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: AppColors.warmWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkBlack,
          side: const BorderSide(color: AppColors.borderMedium),
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ember,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 40),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cream,
        selectedColor: AppColors.ember,
        labelStyle: AppTypography.labelMedium,
        side: const BorderSide(color: AppColors.borderLight),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.warmWhite,
        selectedItemColor: AppColors.ember,
        unselectedItemColor: AppColors.mutedGrey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
