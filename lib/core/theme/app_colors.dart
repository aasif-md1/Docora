import 'package:flutter/material.dart';

/// All semantic and brand colors for Docora.
/// Use these constants throughout the app — never hard-code hex values inline.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF5B4BFF);         // Deep indigo/violet
  static const Color primary500 = Color(0xFF5B4BFF);
  static const Color accentTeal = Color(0xFF18D6C4);      // Electric teal accent
  static const Color success500 = Color(0xFF10B981);
  static const Color error500 = Color(0xFFE5484D);

  // ── Background / Surface (Light) ───────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF7F6FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0EEF8);
  static const Color onSurfaceLight = Color(0xFF1A1A2E);
  static const Color outlineLight = Color(0xFFD1CFE0);

  // ── Background / Surface (Dark) ────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0E0E14);
  static const Color surfaceDark = Color(0xFF18181F);
  static const Color surfaceVariantDark = Color(0xFF22222C);
  static const Color onSurfaceDark = Color(0xFFF0EFF8);
  static const Color outlineDark = Color(0xFF3A3848);

  // ── Background / Surface (AMOLED pure black) ───────────────────────────────
  static const Color backgroundAmoled = Color(0xFF000000);
  static const Color surfaceAmoled = Color(0xFF0A0A0D);
  static const Color surfaceVariantAmoled = Color(0xFF141418);

  // ── Semantic Error ─────────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFE5484D);
  static const Color errorRedDark = Color(0xFFFF6B6B);

  // ── File-type Semantic Colors ──────────────────────────────────────────────
  /// PDF
  static const Color filePdf = Color(0xFFE5484D);
  /// Word (DOCX, DOC, RTF, ODT)
  static const Color fileWord = Color(0xFF2F6BFF);
  /// Excel (XLSX, XLS, CSV, TSV, ODS)
  static const Color fileExcel = Color(0xFF22A45D);
  /// PowerPoint (PPTX, PPT, ODP)
  static const Color filePpt = Color(0xFFF5822A);
  /// Text / Code (TXT, MD, JSON, XML, YAML, HTML, LOG)
  static const Color fileText = Color(0xFF6B7280);
  /// EPUB
  static const Color fileEpub = Color(0xFF8B5CF6);
  /// Images (JPG, PNG, WEBP, GIF, HEIC)
  static const Color fileImage = Color(0xFFEC4899);
  /// Archives (ZIP)
  static const Color fileArchive = Color(0xFFF59E0B);

  // ── User-selectable Accent Options ────────────────────────────────────────
  /// Ordered list of accent color options shown in Settings > Appearance.
  /// Index 0 is the default (brand indigo/violet).
  static const List<Color> accentOptions = [
    Color(0xFF5B4BFF), // Indigo violet (default)
    Color(0xFF18D6C4), // Electric teal
    Color(0xFF2F6BFF), // Cobalt blue
    Color(0xFF22A45D), // Emerald green
    Color(0xFFF5822A), // Warm orange
    Color(0xFFEC4899), // Hot pink
    Color(0xFF8B5CF6), // Soft purple
    Color(0xFFF59E0B), // Amber
  ];

  // ── Tag Colors ─────────────────────────────────────────────────────────────
  static const List<Color> tagColors = [
    Color(0xFFE5484D), // Red
    Color(0xFFF5822A), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFF22A45D), // Green
    Color(0xFF18D6C4), // Teal
    Color(0xFF2F6BFF), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF6B7280), // Grey
  ];

  // ── Gradient Presets ───────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF5B4BFF), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF18D6C4), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
