import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Premium Bottom Sheet container adhering to Docora Design System tokens.
/// Features a drag handle pill, responsive theme adapting to AMOLED, and smooth layout.
class DocoraBottomSheet extends StatelessWidget {
  const DocoraBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.showDragHandle = true,
    this.showCloseButton = false,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showDragHandle;
  final bool showCloseButton;
  final EdgeInsetsGeometry? padding;

  /// Helper to show a Docora styled modal bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    String? subtitle,
    bool isScrollControlled = true,
    bool showCloseButton = false,
  }) {
    AppMotion.subtleHaptic();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(140),
      builder: (ctx) => DocoraBottomSheet(
        title: title,
        subtitle: subtitle,
        showCloseButton: showCloseButton,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;

    final sheetBg = isAmoled ? const Color(0xFF0F0F0F) : colorScheme.surface;
    final borderColor = isAmoled
        ? const Color(0xFF222222)
        : colorScheme.outlineVariant.withAlpha(60);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border(
          top: BorderSide(color: borderColor),
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle Pill
            if (showDragHandle) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withAlpha(120),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Optional Header Row
            if (title != null || showCloseButton) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
            ],

            // Content
            Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// A standardized action row tile for Docora Bottom Sheets.
/// Used for options like Share, Rename, Details, Delete, etc.
class DocoraActionTile extends StatelessWidget {
  const DocoraActionTile({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemColor = isDestructive
        ? colorScheme.error
        : (iconColor ?? colorScheme.onSurface);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        leading: Icon(
          icon,
          size: 20,
          color: itemColor,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: itemColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDestructive
                      ? colorScheme.error.withAlpha(200)
                      : colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing,
        onTap: () {
          AppMotion.subtleHaptic();
          onTap?.call();
        },
      ),
    );
  }
}
