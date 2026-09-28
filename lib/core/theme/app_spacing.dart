/// Spacing scale for Docora — based on a 4dp base unit.
/// Use these constants for all padding, margin, and gap values.
/// Never use raw numeric spacing values outside this file.
abstract final class AppSpacing {
  /// 4dp
  static const double xs = 4;
  /// 8dp
  static const double sm = 8;
  /// 12dp
  static const double md = 12;
  /// 16dp
  static const double lg = 16;
  /// 24dp
  static const double xl = 24;
  /// 32dp
  static const double xxl = 32;
  /// 48dp
  static const double xxxl = 48;

  /// Standard horizontal page padding
  static const double pagePadding = 16;

  /// Minimum tap target size per accessibility guidelines (48dp)
  static const double minTapTarget = 48;

  // ── Radius Aliases ────────────────────────────────────────────────────────
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusPill = 100;
}
