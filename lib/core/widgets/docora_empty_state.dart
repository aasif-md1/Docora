import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:flutter/material.dart';

/// Zero-emoji empty state presentation widget.
class DocoraEmptyState extends StatelessWidget {
  const DocoraEmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.description,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resolvedIconColor = iconColor ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layered aura background with central icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resolvedIconColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: resolvedIconColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    color: resolvedIconColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: resolvedIconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              DocoraButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                size: DocoraButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
