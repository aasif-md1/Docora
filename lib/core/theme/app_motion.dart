import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

/// Motion / animation design tokens for Docora.
/// Aligned with Emil Kowalski's design engineering philosophy:
/// - Never use ease-in for UI animations (feels sluggish)
/// - Use custom easing curves with punch
/// - UI animations should stay under 300ms
/// - Button feedback should be 100-160ms
/// - Modals/drawers can be 200-500ms
abstract final class AppMotion {
  // ── Durations ──────────────────────────────────────────────────────────────
  /// 100ms — instant feedback: button press scale, icon swap
  static const Duration instant = Duration(milliseconds: 100);

  /// 150ms — micro interactions: button press, icon swap, tooltips
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms — standard UI transitions: dropdown, popover, select
  static const Duration normal = Duration(milliseconds: 200);

  /// 300ms — emphasis transitions: modal, drawer, bottom sheet
  static const Duration slow = Duration(milliseconds: 300);

  /// 450ms — large layout transitions: page enter, hero, onboarding
  static const Duration xSlow = Duration(milliseconds: 450);

  // ── Easing Curves (Emil Kowalski's philosophy) ─────────────────────────────
  // NEVER use Curves.easeIn for UI — it starts slow, feels sluggish.
  // Custom cubic curves give the "punch" that makes animations feel intentional.

  /// Strong ease-out — primary curve for elements ENTERING the screen.
  /// Starts fast → instant feedback → decelerates gracefully.
  /// CSS equivalent: cubic-bezier(0.23, 1, 0.32, 1)
  static const Curve enter = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out — for on-screen movement/morphing.
  /// Natural acceleration → deceleration.
  /// CSS equivalent: cubic-bezier(0.77, 0, 0.175, 1)
  static const Curve standard = Cubic(0.77, 0, 0.175, 1);

  /// iOS-like drawer curve — for bottom sheets, drawers, side panels.
  /// CSS equivalent: cubic-bezier(0.32, 0.72, 0, 1)
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Emphasized — Material 3 recommended for large/important transitions
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Decelerate — quick alternative enter curve (lighter than custom enter)
  static const Curve decelerate = Curves.decelerate;

  /// Linear — constant motion (spinners, progress bars, marquees)
  static const Curve linear = Curves.linear;

  /// Exit curve — accelerate out. ONLY for elements LEAVING.
  /// This is the one exception where ease-in is acceptable.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Spring-like bounce — FAB expand, success feedback (subtle, 0.1-0.3 bounce)
  static const Curve spring = Curves.elasticOut;

  // ── Aliases & Utilities ───────────────────────────────────────────────────
  static const Duration shortDuration = fast;
  static const Duration standardDuration = normal;
  static const Curve standardDecel = enter;

  /// Scale factor for button press feedback (0.95-0.98 range)
  static const double pressScale = 0.97;

  /// Starting scale for enter animations (never scale from 0!)
  static const double enterScale = 0.95;

  /// Opacity starting value for enter animations
  static const double enterOpacity = 0.0;

  static void subtleHaptic() {
    HapticFeedback.selectionClick();
  }

  static void mediumHaptic() {
    HapticFeedback.lightImpact();
  }

  static void heavyHaptic() {
    HapticFeedback.mediumImpact();
  }
}
