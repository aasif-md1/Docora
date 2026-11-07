import 'package:flutter/material.dart';

class AccentColorOption {
  const AccentColorOption({
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;
}

/// Centralized, production-grade design tokens and color system for Docora.
/// Follows the strict Master Design System:
/// Primary: #4F46E5, Primary Dark: #3730A3, Primary Light: #EEF2FF, Accent: #0D9488.
abstract final class AppColors {
  // ── Brand Primary Palette ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F6BED); // Indigo-Blue #4F6BED
  static const Color primaryDark = Color(0xFF3B54C4);
  static const Color primaryLight = Color(0xFFE8ECFD); // Light tint #E8ECFD
  static const Color accent = Color(0xFF4F6BED);
  static const Color primaryDarkTheme = Color(0xFF6B84FF);

  // Backward compatibility alias
  static const Color primary500 = primary;
  static const Color accentTeal = accent;

  // ── Neutral Foundation (Light) ─────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color disabled = Color(0xFFCBD5E1);

  // ── Neutral Foundation (Dark) ──────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF121418);
  static const Color surfaceDark = Color(0xFF1C1F26);
  static const Color surfaceElevatedDark = Color(0xFF252932);
  static const Color surfaceVariantDark = Color(0xFF252932);
  static const Color onSurfaceDark = Color(0xFFF1F3F6);
  static const Color primaryTextDark = Color(0xFFF1F3F6);
  static const Color secondaryTextDark = Color(0xFF9AA0A6);
  static const Color borderDark = Color(0xFF2E323B);
  static const Color outlineDark = Color(0xFF2E323B);

  // ── AMOLED Black ───────────────────────────────────────────────────────────
  static const Color backgroundAmoled = Color(0xFF000000);
  static const Color surfaceAmoled = Color(0xFF0A0A0D);
  static const Color surfaceVariantAmoled = Color(0xFF141418);

  // ── Semantic Feedback ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color success500 = success;

  static const Color warning = Color(0xFFD97706);

  static const Color error = Color(0xFFDC2626);
  static const Color errorRed = error;
  static const Color errorRedDark = Color(0xFFF87171);
  static const Color error500 = error;

  static const Color info = Color(0xFF2563EB);

  // ── Consistent Document Category Indicators ────────────────────────────────
  // Neutralized, accessible, professional
  static const Color filePdf = Color(0xFFDC2626);
  static const Color fileWord = Color(0xFF2563EB);
  static const Color fileExcel = Color(0xFF16A34A);
  static const Color filePpt = Color(0xFFD97706);
  static const Color fileText = Color(0xFF64748B);
  static const Color fileEpub = Color(0xFF7C3AED);
  static const Color fileImage = Color(0xFF0D9488);
  static const Color fileArchive = Color(0xFF475569);

  // Minimal brand gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Curated Docora accent color options with unique aesthetic names.
  static const List<AccentColorOption> accentColorOptions = [
    AccentColorOption(name: 'Indigo Pulse', color: Color(0xFF4F6BED)),
    AccentColorOption(name: 'Royal Cobalt', color: Color(0xFF2563EB)),
    AccentColorOption(name: 'Skyline Azure', color: Color(0xFF0EA5E9)),
    AccentColorOption(name: 'Nordic Cyan', color: Color(0xFF06B6D4)),
    AccentColorOption(name: 'Oceanic Teal', color: Color(0xFF0D9488)),
    AccentColorOption(name: 'Mint Aurora', color: Color(0xFF10B981)),
    AccentColorOption(name: 'Emerald Matrix', color: Color(0xFF16A34A)),
    AccentColorOption(name: 'Lime Volt', color: Color(0xFF84CC16)),
    AccentColorOption(name: 'Solar Flare', color: Color(0xFFEAB308)),
    AccentColorOption(name: 'Sunset Amber', color: Color(0xFFD97706)),
    AccentColorOption(name: 'Coral Horizon', color: Color(0xFFF97316)),
    AccentColorOption(name: 'Terracotta Rust', color: Color(0xFFC2410C)),
    AccentColorOption(name: 'Crimson Blaze', color: Color(0xFFE11D48)),
    AccentColorOption(name: 'Sakura Rose', color: Color(0xFFEC4899)),
    AccentColorOption(name: 'Cyberpunk Violet', color: Color(0xFF7C3AED)),
    AccentColorOption(name: 'Neon Amethyst', color: Color(0xFFA855F7)),
  ];

  static const List<Color> accentOptions = [
    Color(0xFF4F6BED), // 0: Indigo Pulse
    Color(0xFF2563EB), // 1: Royal Cobalt
    Color(0xFF0EA5E9), // 2: Skyline Azure
    Color(0xFF06B6D4), // 3: Nordic Cyan
    Color(0xFF0D9488), // 4: Oceanic Teal
    Color(0xFF10B981), // 5: Mint Aurora
    Color(0xFF16A34A), // 6: Emerald Matrix
    Color(0xFF84CC16), // 7: Lime Volt
    Color(0xFFEAB308), // 8: Solar Flare
    Color(0xFFD97706), // 9: Sunset Amber
    Color(0xFFF97316), // 10: Coral Horizon
    Color(0xFFC2410C), // 11: Terracotta Rust
    Color(0xFFE11D48), // 12: Crimson Blaze
    Color(0xFFEC4899), // 13: Sakura Rose
    Color(0xFF7C3AED), // 14: Cyberpunk Violet
    Color(0xFFA855F7), // 15: Neon Amethyst
  ];
}
