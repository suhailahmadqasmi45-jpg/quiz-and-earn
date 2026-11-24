import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette (Step 2 Requirements)
  static const Color primary = Color(0xFF312E81);       // Deep Indigo
  static const Color secondary = Color(0xFF6D28D9);     // Royal Violet
  static const Color accent = Color(0xFF06B6D4);        // Electric Cyan
  static const Color gold = Color(0xFFF5B942);          // Premium Gold
  static const Color goldLight = Color(0xFFFDE68A);     // Soft Gold Light
  static const Color goldDark = Color(0xFFD97706);      // Rich Amber Gold

  // Surface & Backgrounds
  static const Color background = Color(0xFFF8FAFC);    // Main crisp background
  static const Color cardBg = Color(0xFFFFFFFF);        // Pure White card
  static const Color cardBorder = Color(0xFFE2E8F0);    // Subtle slate border
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);   // Light gray fill

  // Frosted Glass & Minimalist Accents
  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x99FFFFFF);
  static const Color graphite = Color(0xFF1F2937);
  static const Color silver = Color(0xFFE2E8F0);

  // Dark Surfaces (Selectively used for ATM Card and dark highlights)
  static const Color darkSurface = Color(0xFF0F172A);   // Slate 900
  static const Color darkCard = Color(0xFF1E1B4B);      // Deep Indigo 950
  static const Color darkSurfaceElevated = Color(0xFF1E293B);

  // Typography
  static const Color textPrimary = Color(0xFF111827);   // Gray 900 (High contrast)
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400
  static const Color textOnDark = Color(0xFFFFFFFF);    // White on dark surfaces
  static const Color textOnDarkMuted = Color(0xFFCBD5E1);

  // Status & Feedback
  static const Color correct = Color(0xFF10B981);       // Emerald Green
  static const Color correctLight = Color(0xFFD1FAE5);
  static const Color wrong = Color(0xFFEF4444);         // Rose Red
  static const Color wrongLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color info = Color(0xFF3B82F6);          // Blue

  // Category Specific Theme Colors
  static const Color catGkPrimary = Color(0xFF312E81);
  static const Color catGkSecondary = Color(0xFF4338CA);
  static const Color catSciencePrimary = Color(0xFF0D9488);
  static const Color catScienceSecondary = Color(0xFF14B8A6);
  static const Color catMathPrimary = Color(0xFF7C3AED);
  static const Color catMathSecondary = Color(0xFF8B5CF6);
  static const Color catSportsPrimary = Color(0xFFEA580C);
  static const Color catSportsSecondary = Color(0xFFF97316);
  static const Color catImagePrimary = Color(0xFFBE185D);
  static const Color catImageSecondary = Color(0xFFEC4899);
  static const Color catMoviesPrimary = Color(0xFFE11D48);
  static const Color catMoviesSecondary = Color(0xFFBE123C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF312E81),
      Color(0xFF4338CA),
      Color(0xFF6D28D9),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBBF24),
      Color(0xFFF5B942),
      Color(0xFFD97706),
    ],
  );

  static const LinearGradient atmCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1B4B), // Deepest indigo
      Color(0xFF0F172A), // Slate 900
      Color(0xFF030712), // Pitch black
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF312E81),
      Color(0xFF4C1D95),
    ],
  );
}
