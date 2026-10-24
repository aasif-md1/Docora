import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DocoraCardVariant { elevated, filled, outlined }

/// A premium card container following Docora's Material 3 styling.
/// Uses semi-transparent shadows instead of solid borders (Emil Kowalski's principle).
/// Interactive cards have press-scale feedback.
class DocoraCard extends StatefulWidget {
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
    this.animate = false,
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
  /// When true, the card will animate in with scale + opacity (enter animation)
  final bool animate;

  @override
  State<DocoraCard> createState() => _DocoraCardState();
}

class _DocoraCardState extends State<DocoraCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppMotion.instant,
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: AppMotion.enter),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);

    Color resolvedBg;
    Border? resolvedBorder;
    List<BoxShadow>? resolvedShadow;

    switch (widget.variant) {
      case DocoraCardVariant.elevated:
        resolvedBg = widget.backgroundColor ?? colorScheme.surface;
        // Semi-transparent shadow instead of solid border (Emil Kowalski)
        resolvedShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
        resolvedBorder = Border.all(
          color: widget.selected
              ? colorScheme.primary
              : widget.borderColor ?? colorScheme.outline.withValues(alpha: 0.08),
          width: widget.selected ? 2 : 1,
        );
      case DocoraCardVariant.filled:
        resolvedBg = widget.backgroundColor ??
            (widget.selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surface);
        resolvedBorder = Border.all(
          color: widget.selected
              ? colorScheme.primary
              : widget.borderColor ?? colorScheme.outline.withValues(alpha: 0.08),
          width: widget.selected ? 2 : 1,
        );
      case DocoraCardVariant.outlined:
        resolvedBg = widget.backgroundColor ?? Colors.transparent;
        resolvedBorder = Border.all(
          color: widget.selected
              ? colorScheme.primary
              : widget.borderColor ?? colorScheme.outline.withValues(alpha: 0.15),
          width: widget.selected ? 2 : 1,
        );
    }

    final bool isInteractive = widget.onTap != null;

    Widget cardContent = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: resolvedBorder,
        boxShadow: resolvedShadow,
      ),
      child: widget.child,
    );

    Widget card = Padding(
      padding: widget.margin,
      child: Material(
        color: resolvedBg,
        borderRadius: radius,
        child: isInteractive
            ? GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: AnimatedBuilder(
                  animation: _pressScale,
                  builder: (context, child) => Transform.scale(
                    scale: _pressScale.value,
                    child: child,
                  ),
                  child: InkWell(
                    borderRadius: radius,
                    onTap: widget.onTap != null
                        ? () {
                            HapticFeedback.lightImpact();
                            widget.onTap!();
                          }
                        : null,
                    onLongPress: widget.onLongPress != null
                        ? () {
                            HapticFeedback.mediumImpact();
                            widget.onLongPress!();
                          }
                        : null,
                    child: cardContent,
                  ),
                ),
              )
            : InkWell(
                borderRadius: radius,
                onLongPress: widget.onLongPress != null
                    ? () {
                        HapticFeedback.mediumImpact();
                        widget.onLongPress!();
                      }
                    : null,
                child: cardContent,
              ),
      ),
    );

    // Enter animation: scale from 0.95 + fade in (never scale from 0!)
    if (widget.animate) {
      card = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppMotion.normal,
        curve: AppMotion.enter,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(
            scale: AppMotion.enterScale + (1.0 - AppMotion.enterScale) * value,
            child: child,
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}
