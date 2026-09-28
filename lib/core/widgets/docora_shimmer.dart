import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading shimmer placeholders that automatically adapt to
/// Light, Dark, and AMOLED themes.
class DocoraShimmer extends StatelessWidget {
  const DocoraShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBase = baseColor ??
        (isDark ? const Color(0xFF1E1E26) : const Color(0xFFE5E7EB));
    final resolvedHighlight = highlightColor ??
        (isDark ? const Color(0xFF2A2A36) : const Color(0xFFF3F4F6));

    return Shimmer.fromColors(
      baseColor: resolvedBase,
      highlightColor: resolvedHighlight,
      child: child,
    );
  }
}

/// A generic rectangular or rounded shimmer placeholder block
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xs),
        ),
      );
}

/// Shimmer placeholder specifically for a document list item
class DocumentListItemSkeleton extends StatelessWidget {
  const DocumentListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) => DocoraShimmer(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon placeholder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBlock(
                      width: double.infinity,
                      height: 14,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBlock(
                      width: 140,
                      height: 10,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Action placeholder
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
}
