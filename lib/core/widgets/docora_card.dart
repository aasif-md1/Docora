import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/clay_decorations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DocoraCardVariant { elevated, filled, outlined }

/// A premium Claymorphism (Soft 3D) card container for Docora.
/// Features inflated tactile surfaces, layered dual shadows, top highlights,
/// and smooth press-scale haptic feedback.
class DocoraCard extends StatefulWidget {
  const DocoraCard({
    required this.child,
    super.key,
    this.variant = DocoraCardVariant.filled,
    this.elevation = ClayElevation.raised,
    this.padding = const EdgeInsets.all(16),
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
  final ClayElevation elevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool selected;

  /// When true, the card animates in with scale + opacity
  final bool animate;

  @override
  State<DocoraCard> createState() => _DocoraCardState();
}

class _DocoraCardState extends State<DocoraCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;
  bool _isPressed = false;

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
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(ClayDecorations.radiusCard);

    BoxDecoration boxDecoration;

    if (widget.variant == DocoraCardVariant.outlined) {
      boxDecoration = BoxDecoration(
        color: widget.backgroundColor ?? Colors.transparent,
        borderRadius: radius,
        border: Border.all(
          color: widget.selected
              ? colorScheme.primary
              : widget.borderColor ?? colorScheme.outline.withAlpha(50),
          width: widget.selected ? 1.5 : 1.0,
        ),
      );
    } else {
      boxDecoration = ClayDecorations.decoration(
        context,
        elevation: widget.elevation,
        borderRadius: radius,
        surfaceColor: widget.backgroundColor,
        isSelected: widget.selected,
        isPressed: _isPressed,
        customBorder: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.selected ? 1.5 : 1.0)
            : null,
      );
    }

    final isInteractive = widget.onTap != null;

    Widget cardBody = DecoratedBox(
      decoration: boxDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
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
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );

    Widget card = Padding(
      padding: widget.margin,
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
                child: cardBody,
              ),
            )
          : cardBody,
    );

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
