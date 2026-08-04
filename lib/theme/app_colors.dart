import 'package:flutter/material.dart';

/// Single-Hue Scale Color Palette (Deep Slate Teal Scale)
/// All shades, tints, surfaces, and accents are derived strictly from a single hue family.
class AppColors {
  // Core Base Hue: Deep Slate Teal (Hue ~ 174°)
  static const Color primary = Color(0xFF0F766E);       // Base Teal 700
  static const Color primaryLight = Color(0xFF14B8A6);  // Base Teal 500
  static const Color primaryDark = Color(0xFF134E4A);   // Base Teal 900
  static const Color primarySubtle = Color(0xFF2DD4BF); // Base Teal 400 (Highlight)
  static const Color primaryDeep = Color(0xFF134E4A);   // Base Teal 900
  static const Color primaryContainer = Color(0xFF042F2C); // Base Teal 950

  // Accent aliases matching the single-hue scale
  static const Color accent = Color(0xFF14B8A6);
  static const Color accentLight = Color(0xFF2DD4BF);

  // OLED Pure Black Surfaces (Dark Mode)
  static const Color backgroundDark = Color(0xFF000000);  // True Black
  static const Color surfaceDark = Color(0xFF121214);     // Deep Obsidian Surface
  static const Color cardDark = Color(0xFF18181C);        // Dark Card
  static const Color borderDark = Color(0xFF2A2A30);      // High-contrast Border

  // Single-Hue Surfaces (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Pure White
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);    // Slate 200

  // Status Colors (Subdued within Slate/Teal System)
  static const Color success = Color(0xFF0F766E);     // Teal Success
  static const Color warning = Color(0xFF0D9488);     // Light Teal Warning
  static const Color error = Color(0xFF991B1B);       // Deep Slate Red
  static const Color info = Color(0xFF0F766E);        // Teal Info

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Single-Hue Monochromatic Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
