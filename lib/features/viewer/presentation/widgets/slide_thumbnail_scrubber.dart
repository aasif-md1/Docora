import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Bottom horizontal slide thumbnail scrubber allowing quick jumping between slides.
class SlideThumbnailScrubber extends StatefulWidget {
  const SlideThumbnailScrubber({
    required this.slides,
    required this.currentSlideIndex,
    required this.onSlideSelected,
    super.key,
  });

  final List<PresentationSlide> slides;
  final int currentSlideIndex;
  final ValueChanged<int> onSlideSelected;

  @override
  State<SlideThumbnailScrubber> createState() => _SlideThumbnailScrubberState();
}

class _SlideThumbnailScrubberState extends State<SlideThumbnailScrubber> {
  final ScrollController _scrollController = ScrollController();

  static const double _thumbnailWidth = 92.0;

  @override
  void didUpdateWidget(SlideThumbnailScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSlideIndex != oldWidget.currentSlideIndex) {
      _scrollToCurrentSlide();
    }
  }

  void _scrollToCurrentSlide() {
    if (!_scrollController.hasClients) return;
    final targetOffset = widget.currentSlideIndex * (_thumbnailWidth + 8.0);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportWidth = _scrollController.position.viewportDimension;

    final centeredOffset = (targetOffset - (viewportWidth / 2) + (_thumbnailWidth / 2))
        .clamp(0.0, maxScroll);

    _scrollController.animateTo(
      centeredOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.slides.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == widget.currentSlideIndex;
          final slide = widget.slides[index];

          return InkWell(
            onTap: () => widget.onSlideSelected(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: _thumbnailWidth,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withAlpha(80),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(50),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Preview snippet
                  Text(
                    slide.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontSize: 10,
                    ),
                  ),
                  // Bottom Indicator: Slide number + Notes icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      if (slide.hasNotes)
                        Icon(
                          LucideIcons.file_text,
                          size: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
