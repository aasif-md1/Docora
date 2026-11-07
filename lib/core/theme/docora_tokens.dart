import 'package:flutter/material.dart';

/// Centralized design tokens for Docora widgets and UI components.
/// Strictly adheres to the minimal, clean, content-focused design system.
abstract final class DocoraTokens {
  // ── Brand Accent ──────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF4F6BED); // Single brand accent
  static const Color accentContainerLight = Color(0xFFE8ECFD);
  static const Color accentContainerDark = Color(0xFF232B4D);

  // ── Light Theme Tokens ────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF2F4F7);
  static const Color textPrimaryLight = Color(0xFF101828);
  static const Color textSecondaryLight = Color(0xFF667085);
  static const Color borderLight = Color(0xFFE4E7EC);

  // ── Dark Theme Tokens ─────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF16181D);
  static const Color surfaceVariantDark = Color(0xFF22252C);
  static const Color textPrimaryDark = Color(0xFFF2F4F7);
  static const Color textSecondaryDark = Color(0xFF98A2B3);
  static const Color borderDark = Color(0xFF2E323B);

  // ── Spacing (8dp Grid) ────────────────────────────────────────────────────
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;

  // ── Corner Radii ──────────────────────────────────────────────────────────
  static const double radiusOuter = 24.0; // Outer widget card
  static const double radiusInner = 12.0; // Inner icon container / chips
  static const double radiusPill = 999.0; // Full pill button

  // ── Typography ────────────────────────────────────────────────────────────
  static const TextStyle widgetTitleLight = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: textPrimaryLight,
    height: 1.35,
  );

  static const TextStyle widgetTitleDark = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: textPrimaryDark,
    height: 1.35,
  );

  static const TextStyle widgetCaptionLight = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: textSecondaryLight,
    height: 1.35,
  );

  static const TextStyle widgetCaptionDark = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: textSecondaryDark,
    height: 1.35,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.3,
  );

  static const TextStyle iconLabelLight = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: textPrimaryLight,
    height: 1.3,
  );

  static const TextStyle iconLabelDark = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: textPrimaryDark,
    height: 1.3,
  );

  static const TextStyle percentageAccent = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: accent,
    height: 1.3,
  );
}

