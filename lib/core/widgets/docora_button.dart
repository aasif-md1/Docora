import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DocoraButtonVariant { primary, secondary, outlined, ghost }

enum DocoraButtonSize { small, medium, large }

/// Standard button for Docora with haptics, loading states, and icon support.
class DocoraButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final double height;
    final double fontSize;
    final EdgeInsets padding;

    switch (size) {
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
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == DocoraButtonVariant.primary
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: fontSize + 4),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    VoidCallback? handleTap() {
      if (onPressed == null || isLoading) return null;
      return () {
        HapticFeedback.lightImpact();
        onPressed!();
      };
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    Widget button;
    switch (variant) {
      case DocoraButtonVariant.primary:
        button = FilledButton(
          onPressed: handleTap(),
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
      case DocoraButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: handleTap(),
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
      case DocoraButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: handleTap(),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
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
            minimumSize: Size(isFullWidth ? double.infinity : 0, height),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
    }

    return button;
  }
}
