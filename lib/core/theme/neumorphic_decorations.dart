import 'package:flutter/material.dart';

/// Neumorphic elevation levels for the Docora design system.
/// Level 1: Subtle (chips, tags, search inputs, badges)
/// Level 2: Raised (cards, list items, category tiles, settings groups, tool cards)
/// Level 3: Prominent (dialogs, bottom sheets, hero widgets)
enum NeumorphicElevation {
  subtle,
  raised,
  prominent,
}

/// Neumorphic depth orientation.
/// - convex: Raised surface with top-left light highlight and bottom-right dark shadow.
/// - concave: Inset/recessed surface (sunken search fields, pressed buttons, active chips).
/// - flat: Neutral level surface with subtle ambient depth.
enum NeumorphicDepth {
  convex,
  concave,
  flat,
}

/// Centralized Neumorphism (Soft UI) Design System for Docora.
///
/// Features:
/// - Directional dual-shadow system (top-left ambient highlight + bottom-right contact shadow).
/// - Tactile convex (raised) and concave (inset/recessed) surface modeling.
/// - Smooth surface transitions tailored for everyday productivity use.
/// - Full adaptive support for Light, Dark, and AMOLED modes.
/// - Zero third-party dependencies, 100% native Flutter rendering.
abstract final class NeumorphicDecorations {
  static const double radiusSubtle = 12.0;
  static const double radiusCard = 16.0;
  static const double radiusProminent = 22.0;
  static const double radiusPill = 999.0;

  /// Creates a Neumorphic [BoxDecoration] based on surface depth and elevation.
  static BoxDecoration decoration(
    BuildContext context, {
    NeumorphicElevation elevation = NeumorphicElevation.raised,
    NeumorphicDepth depth = NeumorphicDepth.convex,
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
    Border? customBorder,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;
    final effectiveAccent = accentColor ?? colorScheme.primary;

    final resolvedRadius = borderRadius ??
        BorderRadius.circular(
          switch (elevation) {
            NeumorphicElevation.subtle => radiusSubtle,
            NeumorphicElevation.raised => radiusCard,
            NeumorphicElevation.prominent => radiusProminent,
          },
        );

    // If pressed, naturally invert convex to concave (tactile button press)
    final effectiveDepth = isPressed ? NeumorphicDepth.concave : depth;

    // 1. Neumorphic Surface Gradient
    final Gradient surfaceGradient = _buildGradient(
      depth: effectiveDepth,
      isDark: isDark,
      isAmoled: isAmoled,
      surfaceColor: surfaceColor,
      isSelected: isSelected,
      accentColor: effectiveAccent,
    );

    // 2. Dual Directional Shadows (Light from Top-Left, Shadow to Bottom-Right)
    final List<BoxShadow> shadows = _buildShadows(
      elevation: elevation,
      depth: effectiveDepth,
      isDark: isDark,
      isAmoled: isAmoled,
      isSelected: isSelected,
      accentColor: effectiveAccent,
    );

    // 3. Highlight Border / Perimeter definition
    final Border border = customBorder ??
        _buildBorder(
          depth: effectiveDepth,
          isDark: isDark,
          isAmoled: isAmoled,
          isSelected: isSelected,
          accentColor: effectiveAccent,
          colorScheme: colorScheme,
        );

    return BoxDecoration(
      gradient: surfaceGradient,
      borderRadius: resolvedRadius,
      boxShadow: shadows,
      border: border,
    );
  }

  /// Helper for raised (convex) information cards and containers.
  static BoxDecoration card(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return decoration(
      context,
      elevation: NeumorphicElevation.raised,
      depth: NeumorphicDepth.convex,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
    );
  }

  /// Helper for small category tiles and tactile action buttons.
  static BoxDecoration tile(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return decoration(
      context,
      elevation: NeumorphicElevation.raised,
      depth: NeumorphicDepth.convex,
      borderRadius: borderRadius ?? BorderRadius.circular(14),
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
    );
  }

  /// Helper for inset/recessed containers like search fields, input text areas, and pressed chips.
  static BoxDecoration inset(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
  }) {
    return decoration(
      context,
      elevation: NeumorphicElevation.subtle,
      depth: NeumorphicDepth.concave,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusSubtle),
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
    );
  }

  /// Helper for subtle chips, badges, and tags.
  static BoxDecoration subtle(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return decoration(
      context,
      elevation: NeumorphicElevation.subtle,
      depth: isSelected ? NeumorphicDepth.concave : NeumorphicDepth.convex,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusSubtle),
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
    );
  }

  /// Helper for modal dialogs and bottom sheets.
  static BoxDecoration prominent(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
  }) {
    return decoration(
      context,
      elevation: NeumorphicElevation.prominent,
      depth: NeumorphicDepth.convex,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusProminent),
      surfaceColor: surfaceColor,
    );
  }

  // ── Internal Gradient Builder ──────────────────────────────────────────────

  static Gradient _buildGradient({
    required NeumorphicDepth depth,
    required bool isDark,
    required bool isAmoled,
    required Color? surfaceColor,
    required bool isSelected,
    required Color accentColor,
  }) {
    if (isSelected) {
      if (isDark) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withAlpha(45),
            accentColor.withAlpha(20),
          ],
        );
      } else {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withAlpha(30),
            accentColor.withAlpha(12),
          ],
        );
      }
    }

    if (depth == NeumorphicDepth.concave) {
      // Inset / Recessed: light catches the lower-right edge, top-left is recessed
      if (isAmoled) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07080A),
            Color(0xFF101217),
          ],
        );
      }
      if (isDark) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14161C),
            Color(0xFF222631),
          ],
        );
      }
      // Light Inset
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE9EDF3),
          Color(0xFFF7F9FC),
        ],
      );
    }

    // Convex (Raised): Top-left is gently lit, bottom-right has soft depth
    if (isAmoled) {
      final base = surfaceColor ?? const Color(0xFF0E1014);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceColor != null ? base.withAlpha(240) : const Color(0xFF14171E),
          surfaceColor != null ? base : const Color(0xFF090A0D),
        ],
      );
    }

    if (isDark) {
      final base = surfaceColor ?? const Color(0xFF1C1F26);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceColor != null ? base.withAlpha(250) : const Color(0xFF242833),
          surfaceColor != null ? base : const Color(0xFF191C23),
        ],
      );
    }

    // Light Convex (Raised): Pure crisp white top-left transitioning to soft background tint
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF4F6F9),
      ],
    );
  }

  // ── Internal Shadow Builder ────────────────────────────────────────────────

  static List<BoxShadow> _buildShadows({
    required NeumorphicElevation elevation,
    required NeumorphicDepth depth,
    required bool isDark,
    required bool isAmoled,
    required bool isSelected,
    required Color accentColor,
  }) {
    if (depth == NeumorphicDepth.concave) {
      // Inset surfaces do not cast prominent outer drop shadows
      if (isDark || isAmoled) {
        return const [
          BoxShadow(
            color: Color(0x35000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ];
      }
      return const [
        BoxShadow(
          color: Color(0x0C0F172A),
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }

    final double dist = switch (elevation) {
      NeumorphicElevation.subtle => 3.0,
      NeumorphicElevation.raised => 5.0,
      NeumorphicElevation.prominent => 8.0,
    };

    final double blur = switch (elevation) {
      NeumorphicElevation.subtle => 7.0,
      NeumorphicElevation.raised => 12.0,
      NeumorphicElevation.prominent => 20.0,
    };

    if (isSelected) {
      return [
        BoxShadow(
          color: accentColor.withAlpha(isDark ? 55 : 35),
          offset: Offset(0, dist),
          blurRadius: blur,
        ),
        BoxShadow(
          color: isDark ? const Color(0x40000000) : const Color(0x0E0F172A),
          offset: Offset(dist * 0.6, dist * 0.6),
          blurRadius: 4,
        ),
      ];
    }

    if (isAmoled) {
      return [
        // Top-left subtle light highlight
        BoxShadow(
          color: const Color(0x18FFFFFF),
          offset: Offset(-dist * 0.7, -dist * 0.7),
          blurRadius: blur * 0.8,
        ),
        // Bottom-right deep dark shadow
        BoxShadow(
          color: const Color(0x85000000),
          offset: Offset(dist, dist),
          blurRadius: blur,
        ),
      ];
    }

    if (isDark) {
      return [
        // Top-left soft highlight
        BoxShadow(
          color: const Color(0x12FFFFFF),
          offset: Offset(-dist * 0.7, -dist * 0.7),
          blurRadius: blur * 0.7,
        ),
        // Bottom-right contact shadow
        BoxShadow(
          color: const Color(0x55000000),
          offset: Offset(dist, dist),
          blurRadius: blur,
        ),
        // Soft ambient floor shadow
        BoxShadow(
          color: const Color(0x30000000),
          offset: Offset(0, dist * 0.8),
          blurRadius: blur * 1.2,
          spreadRadius: -2,
        ),
      ];
    }

    // Light Theme: Classic Soft UI dual directional shadow
    return [
      // Top-left crisp light highlight
      BoxShadow(
        color: const Color(0xFFFFFFFF),
        offset: Offset(-dist, -dist),
        blurRadius: blur * 0.8,
        spreadRadius: 0,
      ),
      // Bottom-right soft contact shadow
      BoxShadow(
        color: const Color(0x150F172A),
        offset: Offset(dist, dist),
        blurRadius: blur,
        spreadRadius: 0,
      ),
      // Subtle ambient ground shadow
      BoxShadow(
        color: const Color(0x0A0F172A),
        offset: Offset(0, dist * 0.8),
        blurRadius: blur * 1.2,
        spreadRadius: -2,
      ),
    ];
  }

  // ── Internal Border Builder ────────────────────────────────────────────────

  static Border _buildBorder({
    required NeumorphicDepth depth,
    required bool isDark,
    required bool isAmoled,
    required bool isSelected,
    required Color accentColor,
    required ColorScheme colorScheme,
  }) {
    if (isSelected) {
      return Border.all(
        color: accentColor,
        width: 1.5,
      );
    }

    if (depth == NeumorphicDepth.concave) {
      if (isAmoled) {
        return Border.all(color: const Color(0x1FFFFFFF), width: 1.0);
      }
      if (isDark) {
        return Border.all(color: const Color(0x16FFFFFF), width: 1.0);
      }
      return Border.all(color: const Color(0x140F172A), width: 1.0);
    }

    if (isAmoled) {
      return Border.all(color: const Color(0x22FFFFFF), width: 0.8);
    }

    if (isDark) {
      return Border.all(color: const Color(0x18FFFFFF), width: 0.8);
    }

    // Light Theme: Smooth hairline perimeter for razor-sharp definition
    return Border.all(
      color: const Color(0x0E0F172A),
      width: 0.8,
    );
  }
}

