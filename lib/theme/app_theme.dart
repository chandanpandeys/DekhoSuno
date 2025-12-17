import 'package:flutter/material.dart';

/// DekhoSuno Premium Design System
/// Accessibility-first theming for Visual (HI) and Audio (VI) modes

// ============================================================================
// COLOR SYSTEM
// ============================================================================

class AppColors {
  // Primary Brand Colors
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color primaryPurpleLight = Color(0xFF9A82DB);
  static const Color primaryPurpleDark = Color(0xFF4A3880);

  // Audio Mode (High Contrast for Visual Appeal to VI's caring family)
  static const Color audioBackground = Color(0xFF0A0A0F);
  static const Color audioPrimary = Color(0xFF00D4AA); // Vibrant teal
  static const Color audioSecondary = Color(0xFFFFB800); // Warm gold
  static const Color audioAccent = Color(0xFFFF6B6B); // Alert red
  static const Color audioSurface = Color(0xFF1A1A24);
  static const Color audioText = Color(0xFFFFFFFF);
  static const Color audioTextMuted = Color(0xFFB0B0B0);

  // Visual Mode (Calming, modern palette)
  static const Color visualBackground = Color(0xFFF8F9FC);
  static const Color visualPrimary = Color(0xFF5B67CA); // Soft indigo
  static const Color visualSecondary = Color(0xFF43B7A8); // Calm teal
  static const Color visualAccent = Color(0xFFFF7B54); // Warm coral
  static const Color visualSurface = Color(0xFFFFFFFF);
  static const Color visualText = Color(0xFF1A1D29);
  static const Color visualTextMuted = Color(0xFF6B7280);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Glassmorphism
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassBlack = Color(0x33000000);
  static const Color glassBorder = Color(0x22FFFFFF);

  // Gradients
  static const LinearGradient audioPrimaryGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient visualPrimaryGradient = LinearGradient(
    colors: [Color(0xFF5B67CA), Color(0xFF43B7A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient landingTopGradient = LinearGradient(
    colors: [Color(0xFFF8F9FC), Color(0xFFE8ECF4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient landingBottomGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF1A1A28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // AI-Inspired Vibe Colors
  static const Color aiGlow = Color(0xFF00F5D4); // Cyan glow
  static const Color aiPurple = Color(0xFF9B5DE5); // AI purple
  static const Color aiPink = Color(0xFFF15BB5); // Accent pink
  static const Color aiBlue = Color(0xFF00BBF9); // Electric blue

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x11FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================================
// TYPOGRAPHY
// ============================================================================

class AppTypography {
  // Font Family
  static const String fontFamily = 'Roboto';

  // Accessibility-first sizing (minimum 16sp for body text)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Hindi/Devanagari specific
  static const TextStyle hindiDisplay = TextStyle(
    fontFamily: 'Noto Sans Devanagari',
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.4,
  );

  static const TextStyle hindiBody = TextStyle(
    fontFamily: 'Noto Sans Devanagari',
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.6,
  );
}

// ============================================================================
// SPACING & SIZING
// ============================================================================

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Touch target sizes (minimum 48dp for accessibility)
  static const double minTouchTarget = 48;
  static const double iconButtonSize = 56;
  static const double fabSize = 64;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

// ============================================================================
// ANIMATIONS
// ============================================================================

class AppAnimations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutQuart;
}

// ============================================================================
// SHADOWS
// ============================================================================

class AppShadows {
  static List<BoxShadow> get small => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}

// ============================================================================
// THEME DATA
// ============================================================================

class AppTheme {
  /// Light theme for Visual Mode (Hearing Impaired users)
  static ThemeData get visualTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,
        colorScheme: ColorScheme.light(
          primary: AppColors.visualPrimary,
          secondary: AppColors.visualSecondary,
          tertiary: AppColors.visualAccent,
          surface: AppColors.visualSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.visualText,
        ),
        scaffoldBackgroundColor: AppColors.visualBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.visualSurface,
          foregroundColor: AppColors.visualText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.titleLarge.copyWith(
            color: AppColors.visualText,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.visualSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.visualPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTypography.labelLarge,
          ),
        ),
        iconTheme: const IconThemeData(
          size: 24,
          color: AppColors.visualText,
        ),
      );

  /// Dark theme for Audio Mode (Visually Impaired users)
  static ThemeData get audioTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: AppTypography.fontFamily,
        colorScheme: ColorScheme.dark(
          primary: AppColors.audioPrimary,
          secondary: AppColors.audioSecondary,
          tertiary: AppColors.audioAccent,
          surface: AppColors.audioSurface,
          onPrimary: AppColors.audioBackground,
          onSecondary: AppColors.audioBackground,
          onSurface: AppColors.audioText,
        ),
        scaffoldBackgroundColor: AppColors.audioBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.audioSurface,
          foregroundColor: AppColors.audioText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.titleLarge.copyWith(
            color: AppColors.audioText,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.audioSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.audioPrimary,
            foregroundColor: AppColors.audioBackground,
            minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          size: 24,
          color: AppColors.audioText,
        ),
      );
}
