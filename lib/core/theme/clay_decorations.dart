import 'package:docora/core/theme/neumorphic_decorations.dart';
import 'package:flutter/material.dart';

export 'package:docora/core/theme/neumorphic_decorations.dart';

/// Legacy alias for [NeumorphicElevation]
typedef ClayElevation = NeumorphicElevation;

/// Master decoration helper providing Neumorphic (Soft UI) styling across Docora.
abstract final class ClayDecorations {
  static const double radiusSubtle = NeumorphicDecorations.radiusSubtle;
  static const double radiusCard = NeumorphicDecorations.radiusCard;
  static const double radiusProminent = NeumorphicDecorations.radiusProminent;
  static const double radiusPill = NeumorphicDecorations.radiusPill;

  static BoxDecoration decoration(
    BuildContext context, {
    NeumorphicElevation elevation = NeumorphicElevation.raised,
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
    Border? customBorder,
  }) {
    return NeumorphicDecorations.decoration(
      context,
      elevation: elevation,
      depth: isPressed ? NeumorphicDepth.concave : NeumorphicDepth.convex,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
      customBorder: customBorder,
    );
  }

  static BoxDecoration card(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return NeumorphicDecorations.card(
      context,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
    );
  }

  static BoxDecoration tile(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return NeumorphicDecorations.tile(
      context,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
    );
  }

  static BoxDecoration subtle(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
    bool isPressed = false,
  }) {
    return NeumorphicDecorations.subtle(
      context,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
      isPressed: isPressed,
    );
  }

  static BoxDecoration inset(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
    Color? accentColor,
    bool isSelected = false,
  }) {
    return NeumorphicDecorations.inset(
      context,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      isSelected: isSelected,
    );
  }

  static BoxDecoration prominent(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? surfaceColor,
  }) {
    return NeumorphicDecorations.prominent(
      context,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
    );
  }
}
