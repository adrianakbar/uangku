import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Color
  static const Color primaryLight = Color(0xFF35858E);
  static const Color primaryDark = Color(0xFF35858E);

  // Secondary Color
  static const Color secondary = Color(0xFF7DA78C);

  // Tertiary Color
  static const Color tertiaryLight = Color(0xFFC2D099);
  static const Color tertiaryDark = Color(0xFFC2D099);

  // Surface and Backgrounds
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color bgDark = Color(0xFF0E1122);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF151929);

  // Text Colors (Light Mode)
  static const Color textLightPrimary = Color(0xFF1E293B);
  static const Color textLightSecondary = Color(0xFF475569);
  static const Color textLightTertiary = Color(0xFF64748B);

  // Text Colors (Dark Mode)
  static const Color textDarkPrimary = Colors.white;
  static const Color textDarkSecondary = Colors.white70;
  static const Color textDarkTertiary = Colors.white54;

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color danger = Color(0xFFFF3D00);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF35858E);

  // Gradients
  static LinearGradient primaryGradient(bool isDark) {
    return LinearGradient(
      colors: isDark 
          ? [primaryDark, primaryDark.withOpacity(0.7)] 
          : [primaryLight, primaryLight.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryLight, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTypography {
  static String? get fontFamily => GoogleFonts.inter().fontFamily;

  static TextStyle heading1(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: color ?? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
    );
  }

  static TextStyle heading2(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: color ?? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
    );
  }

  static TextStyle body(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color ?? (isDark ? AppColors.textDarkTertiary : AppColors.textLightTertiary),
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
}

class AppBlur {
  static const double standard = 20.0;
  static const double intense = 30.0;
}

class AppTheme {
  static ThemeData lightTheme({String? fontFamily}) {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: fontFamily ?? AppTypography.fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiaryLight,
        surface: AppColors.bgLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
      ),
    );
  }

  static ThemeData darkTheme({String? fontFamily}) {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: fontFamily ?? AppTypography.fontFamily,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiaryDark,
        surface: AppColors.bgDark,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
      ),
    );
  }
}
