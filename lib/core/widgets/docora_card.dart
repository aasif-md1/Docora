import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DocoraCardVariant { elevated, filled, outlined }

/// A premium card container following Docora's Material 3 styling.
class DocoraCard extends StatelessWidget {
  const DocoraCard({
    required this.child,
    super.key,
    this.variant = DocoraCardVariant.filled,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.selected = false,
  });

  final Widget child;
  final DocoraCardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    Color resolvedBg;
    Border? resolvedBorder;
    List<BoxShadow>? resolvedShadow;

    switch (variant) {
      case DocoraCardVariant.elevated:
        resolvedBg = backgroundColor ?? colorScheme.surface;
        resolvedShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        resolvedBorder = Border.all(
          color: selected
              ? colorScheme.primary
              : borderColor ?? colorScheme.outline.withValues(alpha: 0.12),
          width: selected ? 2 : 1,
        );
      case DocoraCardVariant.filled:
        resolvedBg = backgroundColor ??
            (selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surface);
        resolvedBorder = Border.all(
          color: selected
              ? colorScheme.primary
              : borderColor ?? colorScheme.outline.withValues(alpha: 0.1),
          width: selected ? 2 : 1,
        );
      case DocoraCardVariant.outlined:
        resolvedBg = backgroundColor ?? Colors.transparent;
        resolvedBorder = Border.all(
          color: selected
              ? colorScheme.primary
              : borderColor ?? colorScheme.outline,
          width: selected ? 2 : 1,
        );
    }

    return Padding(
      padding: margin,
      child: Material(
        color: resolvedBg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          onLongPress: onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                }
              : null,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: resolvedBorder,
              boxShadow: resolvedShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
