import 'dart:async';

import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:docora/features/viewer/presentation/providers/presentation_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_reading_mode_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/presentation_controls_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/presentation_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/presentation_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/slide_renderer_widget.dart';
import 'package:docora/features/viewer/presentation/widgets/slide_thumbnail_scrubber.dart';
import 'package:docora/features/viewer/presentation/widgets/speaker_notes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Full-featured PowerPoint (.pptx, .ppt) Presentation Viewer for Docora.
/// Supports aspect-ratio preserved slide rendering (16:9 / 4:3), interactive slide
/// swipe navigation, speaker notes drawer, auto-play slideshow timer, in-deck search,
/// and immersive fullscreen presentation mode.
class PresentationViewerScreen extends ConsumerStatefulWidget {
  const PresentationViewerScreen({
    required this.filePath,
    super.key,
  });

  final String filePath;

  @override
  ConsumerState<PresentationViewerScreen> createState() =>
      _PresentationViewerScreenState();
}

class _PresentationViewerScreenState
    extends ConsumerState<PresentationViewerScreen> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  bool _isSearchVisible = false;
  int _currentMatchIndex = 0;
  final List<int> _matchedSlideIndices = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordProgress(0, 1);
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _recordProgress(int slideIndex, int totalSlides) {
    try {
      ref.read(documentRepositoryProvider).saveReadingProgress(
            path: widget.filePath,
            pageIndex: slideIndex + 1,
            totalPages: totalSlides > 0 ? totalSlides : 1,
          );
    } on Object catch (_) {}
  }

  void _onSlideChanged(int index, int totalSlides) {
    ref.read(presentationActiveSlideProvider.notifier).state = index;
    _recordProgress(index, totalSlides);
  }

  void _goToSlide(int index) {
    if (!_pageController.hasClients) return;
    AppMotion.subtleHaptic();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _toggleAutoPlay(int totalSlides) {
    final isPlaying = ref.read(presentationAutoPlayProvider);
    if (isPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay(totalSlides);
    }
  }

  void _startAutoPlay(int totalSlides) {
    _autoPlayTimer?.cancel();
    ref.read(presentationAutoPlayProvider.notifier).state = true;
    final intervalSeconds = ref.read(presentationAutoPlayIntervalProvider);

    _autoPlayTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      final current = ref.read(presentationActiveSlideProvider);
      if (current < totalSlides - 1) {
        _goToSlide(current + 1);
      } else {
        _stopAutoPlay();
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    ref.read(presentationAutoPlayProvider.notifier).state = false;
  }

  void _toggleFullscreen() {
    final isFullscreen = ref.read(presentationFullscreenProvider);
    final next = !isFullscreen;
    ref.read(presentationFullscreenProvider.notifier).state = next;

    if (next) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _showSpeakerNotes(PresentationSlide slide) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => SpeakerNotesSheet(
        slideIndex: slide.slideIndex,
        notes: slide.speakerNotes,
      ),
    );
  }

  void _showInfoSheet(PresentationDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => PresentationInfoSheet(document: doc),
    );
  }

  void _showIntervalDialog() {
    final currentInterval = ref.read(presentationAutoPlayIntervalProvider);
    final options = [3, 5, 8, 10, 15];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slide Transition Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((sec) => ListTile(
            title: Text('$sec seconds per slide'),
            trailing: currentInterval == sec
                ? Icon(
                    LucideIcons.check,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(presentationAutoPlayIntervalProvider.notifier).state = sec;
              Navigator.pop(context);
              if (ref.read(presentationAutoPlayProvider)) {
                final doc = ref.read(presentationDocumentProvider(widget.filePath)).valueOrNull;
                if (doc != null) _startAutoPlay(doc.slideCount);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _onSearchQueryChanged(String query, List<PresentationSlide> slides) {
    setState(() {
      _matchedSlideIndices.clear();
      _currentMatchIndex = 0;

      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        for (int i = 0; i < slides.length; i++) {
          final s = slides[i];
          if (s.displayTitle.toLowerCase().contains(q) ||
              s.plainText.toLowerCase().contains(q) ||
              (s.speakerNotes != null && s.speakerNotes!.toLowerCase().contains(q))) {
            _matchedSlideIndices.add(i);
          }
        }

        if (_matchedSlideIndices.isNotEmpty) {
          _goToSlide(_matchedSlideIndices.first);
        }
      }
    });
  }

  void _nextMatch() {
    if (_matchedSlideIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchedSlideIndices.length;
      _goToSlide(_matchedSlideIndices[_currentMatchIndex]);
    });
  }

  void _previousMatch() {
    if (_matchedSlideIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchedSlideIndices.length) %
              _matchedSlideIndices.length;
      _goToSlide(_matchedSlideIndices[_currentMatchIndex]);
    });
  }

  Future<void> _shareFile() async {
    try {
      await Share.shareXFiles([XFile(widget.filePath)]);
    } on Object catch (_) {}
  }

  Future<void> _openExternal() async {
    try {
      await OpenFile.open(widget.filePath);
    } on Object catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final docAsync = ref.watch(presentationDocumentProvider(widget.filePath));
    final activeIndex = ref.watch(presentationActiveSlideProvider);
    final isFullscreen = ref.watch(presentationFullscreenProvider);
    final isPlaying = ref.watch(presentationAutoPlayProvider);
    final readingMode = ref.watch(presentationReadingModeProvider);
    final isWakelockActive = ref.watch(presentationWakelockProvider);

    final fileName = p.basename(widget.filePath);
    final ext = p.extension(widget.filePath).toLowerCase().replaceAll('.', '').toUpperCase();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchVisible) {
          setState(() {
            _isSearchVisible = false;
            _matchedSlideIndices.clear();
          });
          return;
        }
        if (isFullscreen) {
          _toggleFullscreen();
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
      backgroundColor: isFullscreen
          ? Colors.black
          : colorScheme.surface,
      appBar: isFullscreen
          ? null
          : AppBar(
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrow_left),
                onPressed: () {
                  if (_isSearchVisible) {
                    setState(() {
                      _isSearchVisible = false;
                      _matchedSlideIndices.clear();
                    });
                    return;
                  }
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8, right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ext,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearchVisible ? LucideIcons.search_x : LucideIcons.search,
                    size: 20,
                  ),
                  tooltip: 'Search slides',
                  onPressed: () {
                    AppMotion.subtleHaptic();
                    setState(() {
                      _isSearchVisible = !_isSearchVisible;
                      if (!_isSearchVisible) {
                        _matchedSlideIndices.clear();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.sun_moon, size: 20),
                  tooltip: 'Reading mode',
                  onPressed: () {
                    PdfReadingModeSheet.show(
                      context: context,
                      currentMode: readingMode,
                      onModeSelected: (mode) {
                        ref.read(presentationReadingModeProvider.notifier).state = mode;
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(LucideIcons.maximize, size: 20),
                  tooltip: 'Present fullscreen',
                  onPressed: _toggleFullscreen,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.ellipsis_vertical, size: 20),
                  onSelected: (val) {
                    final doc = docAsync.valueOrNull;
                    switch (val) {
                      case 'info':
                        if (doc != null) _showInfoSheet(doc);
                      case 'interval':
                        _showIntervalDialog();
                      case 'wakelock':
                        ref.read(presentationWakelockProvider.notifier).toggle();
                      case 'share':
                        _shareFile();
                      case 'open_external':
                        _openExternal();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(LucideIcons.info, size: 18),
                          SizedBox(width: 12),
                          Text('Presentation Info'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'interval',
                      child: Row(
                        children: [
                          Icon(LucideIcons.timer, size: 18),
                          SizedBox(width: 12),
                          Text('Auto-play Interval'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'wakelock',
                      child: Row(
                        children: [
                          Icon(
                            isWakelockActive ? LucideIcons.eye : LucideIcons.eye_off,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(isWakelockActive
                              ? 'Disable Screen Awake'
                              : 'Keep Screen Awake'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(LucideIcons.share_2, size: 18),
                          SizedBox(width: 12),
                          Text('Share File'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'open_external',
                      child: Row(
                        children: [
                          Icon(LucideIcons.external_link, size: 18),
                          SizedBox(width: 12),
                          Text('Open in External App'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: docAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading presentation deck...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.circle_alert,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load presentation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.refresh(presentationDocumentProvider(widget.filePath)),
                  icon: const Icon(LucideIcons.refresh_cw, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (doc) {
          if (doc.slides.isEmpty) {
            return const Center(
              child: Text('No slides found in this presentation.'),
            );
          }

          final safeIndex = activeIndex.clamp(0, doc.slideCount - 1);
          final currentSlide = doc.slides[safeIndex];

          return Column(
            children: [
              // In-deck Search Bar
              if (_isSearchVisible && !isFullscreen)
                PresentationSearchBar(
                  totalMatches: _matchedSlideIndices.length,
                  currentMatchIndex: _currentMatchIndex,
                  onQueryChanged: (q) => _onSearchQueryChanged(q, doc.slides),
                  onPreviousMatch: _previousMatch,
                  onNextMatch: _nextMatch,
                  onClose: () {
                    setState(() {
                      _isSearchVisible = false;
                      _matchedSlideIndices.clear();
                    });
                  },
                ),

              // Slide Viewport
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: doc.slideCount,
                      onPageChanged: (idx) => _onSlideChanged(idx, doc.slideCount),
                      itemBuilder: (context, index) => SlideRendererWidget(
                        slide: doc.slides[index],
                        aspectRatio: doc.aspectRatio,
                        readingMode: readingMode,
                        isFullscreen: isFullscreen,
                      ),
                    ),

                    // Fullscreen Presentation Overlay (Floating Controls)
                    if (isFullscreen)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: SafeArea(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${safeIndex + 1} / ${doc.slideCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.minimize,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  onPressed: _toggleFullscreen,
                                  tooltip: 'Exit fullscreen',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Slide Thumbnail Scrubber (hidden in fullscreen)
              if (!isFullscreen)
                SlideThumbnailScrubber(
                  slides: doc.slides,
                  currentSlideIndex: safeIndex,
                  onSlideSelected: _goToSlide,
                ),

              // Bottom Controls Bar (hidden in fullscreen)
              if (!isFullscreen)
                PresentationControlsBar(
                  currentIndex: safeIndex,
                  totalSlides: doc.slideCount,
                  onPrevious: safeIndex > 0 ? () => _goToSlide(safeIndex - 1) : null,
                  onNext: safeIndex < doc.slideCount - 1
                      ? () => _goToSlide(safeIndex + 1)
                      : null,
                  isPlaying: isPlaying,
                  onTogglePlay: () => _toggleAutoPlay(doc.slideCount),
                  hasNotes: currentSlide.hasNotes,
                  onToggleNotes: () => _showSpeakerNotes(currentSlide),
                  isFullscreen: isFullscreen,
                  onToggleFullscreen: _toggleFullscreen,
                ),
            ],
          );
        },
      ),
    ),
    );
  }
}
