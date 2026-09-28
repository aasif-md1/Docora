import 'dart:ui';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Floating bottom scrubber bar for page scrubbing, jumping, and zooming in PDF viewer.
class PdfBottomScrubber extends StatelessWidget {
  const PdfBottomScrubber({
    required this.currentPage,
    required this.totalPages,
    required this.currentZoom,
    required this.onPageScrub,
    required this.onJumpTap,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final double currentZoom;
  final ValueChanged<int> onPageScrub;
  final VoidCallback onJumpTap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectiveCurrent = currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
    final effectiveTotal = totalPages > 0 ? totalPages : 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surface.withAlpha(200)
                    : colorScheme.surface.withAlpha(225),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(80),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 80 : 30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Page jump button & Slider
                  Row(
                    children: [
                      InkWell(
                        onTap: onJumpTap,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$effectiveCurrent / $effectiveTotal',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.arrow_up_down,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: effectiveTotal > 1
                            ? SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                ),
                                child: Slider(
                                  value: effectiveCurrent.toDouble(),
                                  min: 1.0,
                                  max: effectiveTotal.toDouble(),
                                  divisions: effectiveTotal - 1,
                                  onChanged: (val) {
                                    onPageScrub(val.round());
                                  },
                                ),
                              )
                            : const SizedBox(height: 16),
                      ),
                    ],
                  ),

                  // Row 2: Zoom Controls & quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.zoom_out, size: 18),
                        tooltip: 'Zoom out',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: onZoomOut,
                      ),
                      InkWell(
                        onTap: onResetZoom,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            '${(currentZoom * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.zoom_in, size: 18),
                        tooltip: 'Zoom in',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: onZoomIn,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        icon: const Icon(LucideIcons.maximize_2, size: 18),
                        tooltip: 'Fit to width / Reset',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: onResetZoom,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
