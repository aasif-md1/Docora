import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DocoraButtonVariant { primary, secondary, outlined, ghost }

enum DocoraButtonSize { small, medium, large }

/// Standard button for Docora with haptics, press-scale feedback, loading states, and icon support.
/// Press-scale follows Emil Kowalski's philosophy: buttons must feel responsive
/// with scale(0.97) on press, using 100-160ms ease-out curves.
class DocoraButton extends StatefulWidget {
  const DocoraButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.variant = DocoraButtonVariant.primary,
    this.size = DocoraButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DocoraButtonVariant variant;
  final DocoraButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<DocoraButton> createState() => _DocoraButtonState();
}

class _DocoraButtonState extends State<DocoraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppMotion.instant,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppMotion.enter,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final double height;
    final double fontSize;
    final EdgeInsets padding;

    switch (widget.size) {
      case DocoraButtonSize.small:
        height = 36;
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md);
      case DocoraButtonSize.medium:
        height = 44;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
      case DocoraButtonSize.large:
        height = 52;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl);
    }

    final Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.variant == DocoraButtonVariant.primary
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: fontSize + 4),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    VoidCallback? handleTap() {
      if (widget.onPressed == null || widget.isLoading) return null;
      return () {
        HapticFeedback.lightImpact();
        widget.onPressed!();
      };
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    Widget button;
    switch (widget.variant) {
      case DocoraButtonVariant.primary:
        button = FilledButton(
          onPressed: handleTap(),
          style: FilledButton.styleFrom(
            minimumSize: Size(widget.isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
      case DocoraButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: handleTap(),
          style: FilledButton.styleFrom(
            minimumSize: Size(widget.isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
      case DocoraButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: handleTap(),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(widget.isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
            side: BorderSide(color: colorScheme.outline),
          ),
          child: content,
        );
      case DocoraButtonVariant.ghost:
        button = TextButton(
          onPressed: handleTap(),
          style: TextButton.styleFrom(
            minimumSize: Size(widget.isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: button,
      ),
    );
  }
}
