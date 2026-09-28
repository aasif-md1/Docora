import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

/// Motion / animation design tokens for Docora.
/// Use these for all animation durations and curves — never magic numbers.
abstract final class AppMotion {
  // ── Durations ──────────────────────────────────────────────────────────────
  /// 150ms — micro interactions: button press, icon swap
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — standard transitions: page fade, card expand
  static const Duration normal = Duration(milliseconds: 250);

  /// 400ms — emphasis transitions: hero, bottom sheet, onboarding
  static const Duration slow = Duration(milliseconds: 400);

  /// 600ms — large layout transitions: splash to home
  static const Duration xSlow = Duration(milliseconds: 600);

  // ── Easing Curves ──────────────────────────────────────────────────────────
  /// Standard ease — general purpose
  static const Curve standard = Curves.easeInOut;

  /// Decelerate — elements entering the screen
  static const Curve enter = Curves.easeOut;

  /// Accelerate — elements leaving the screen
  static const Curve exit = Curves.easeIn;

  /// Emphasized — large/important transitions (Material 3 recommended)
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Spring-like bounce — FAB expand, success feedback
  static const Curve spring = Curves.elasticOut;

  // ── Aliases & Utilities ───────────────────────────────────────────────────
  static const Duration shortDuration = fast;
  static const Duration standardDuration = normal;
  static const Curve standardDecel = enter;

  static void subtleHaptic() {
    HapticFeedback.selectionClick();
  }

  static void mediumHaptic() {
    HapticFeedback.lightImpact();
  }
}
