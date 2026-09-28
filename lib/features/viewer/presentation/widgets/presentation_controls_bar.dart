import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Bottom presentation control toolbar for slide navigation, slideshow auto-play,
/// speaker notes drawer toggle, and fullscreen presentation mode.
class PresentationControlsBar extends StatelessWidget {
  const PresentationControlsBar({
    required this.currentIndex,
    required this.totalSlides,
    required this.onPrevious,
    required this.onNext,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.hasNotes,
    required this.onToggleNotes,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    super.key,
  });

  final int currentIndex;
  final int totalSlides;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final bool hasNotes;
  final VoidCallback onToggleNotes;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous Slide
            IconButton(
              icon: const Icon(LucideIcons.chevron_left, size: 20),
              onPressed: onPrevious,
              tooltip: 'Previous slide',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

            // Slide Counter (e.g., "3 of 12")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${currentIndex + 1} of $totalSlides',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // Next Slide
            IconButton(
              icon: const Icon(LucideIcons.chevron_right, size: 20),
              onPressed: onNext,
              tooltip: 'Next slide',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

            const Spacer(),

            // Auto-play slideshow toggle
            IconButton(
              icon: Icon(
                isPlaying ? LucideIcons.pause : LucideIcons.play,
                size: 20,
                color: isPlaying ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              onPressed: onTogglePlay,
              tooltip: isPlaying ? 'Pause slideshow' : 'Play slideshow',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

            // Speaker notes toggle
            IconButton(
              icon: Icon(
                LucideIcons.file_text,
                size: 20,
                color: hasNotes ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              onPressed: onToggleNotes,
              tooltip: 'Speaker notes',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

            // Fullscreen presentation toggle
            IconButton(
              icon: Icon(
                isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
                size: 20,
              ),
              onPressed: onToggleFullscreen,
              tooltip: isFullscreen ? 'Exit presentation' : 'Present slideshow',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}
