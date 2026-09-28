import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/epub_models.dart';
import 'package:docora/features/viewer/presentation/providers/epub_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_chapter_view.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_font_size_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_toc_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Full-featured EPUB E-Book Reader for Docora.
/// Provides page-by-page chapter browsing, Table of Contents drawer,
/// font scaling, eye-comfort themes (Normal, Sepia, Dark), wakelock toggling,
/// and offline reading progress persistence via Drift SQLite.
class EpubViewerScreen extends ConsumerStatefulWidget {
  const EpubViewerScreen({
    required this.filePath,
    super.key,
  });

  final String filePath;

  @override
  ConsumerState<EpubViewerScreen> createState() => _EpubViewerScreenState();
}

class _EpubViewerScreenState extends ConsumerState<EpubViewerScreen> {
  late PageController _pageController;
  bool _isUiVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recordProgress(int chapterIndex, int totalChapters) {
    if (totalChapters <= 0) return;
    try {
      ref.read(documentRepositoryProvider).saveReadingProgress(
            path: widget.filePath,
            pageIndex: chapterIndex + 1,
            totalPages: totalChapters,
          );
    } on Object catch (_) {}
  }

  void _goToChapter(int index, int totalChapters) {
    if (index >= 0 && index < totalChapters) {
      ref.read(epubActiveChapterIndexProvider.notifier).state = index;
      _pageController.animateToPage(
        index,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
      _recordProgress(index, totalChapters);
    }
  }

  void _showTocSheet(BuildContext context, EpubDocument doc, int currentIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EpubTocSheet(
        tocEntries: doc.toc,
        currentChapterIndex: currentIndex,
        onChapterSelected: (targetIndex) => _goToChapter(targetIndex, doc.chapterCount),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final currentFontSize = ref.read(epubFontSizeProvider);
    final currentReadingMode = ref.read(epubReadingModeProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EpubFontSizeSheet(
        currentFontSize: currentFontSize,
        onFontSizeChanged: (newSize) {
          ref.read(epubFontSizeProvider.notifier).state = newSize;
        },
        currentReadingMode: currentReadingMode,
        onReadingModeChanged: (newMode) {
          ref.read(epubReadingModeProvider.notifier).state = newMode;
        },
      ),
    );
  }

  void _showInfoSheet(BuildContext context, EpubDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EpubInfoSheet(document: doc),
    );
  }

  void _shareFile() {
    Share.shareXFiles([XFile(widget.filePath)]);
  }

  void _openInExternalApp() {
    OpenFile.open(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileName = p.basename(widget.filePath);

    final epubAsync = ref.watch(epubDocumentProvider(widget.filePath));
    final activeChapterIndex = ref.watch(epubActiveChapterIndexProvider);
    final fontSize = ref.watch(epubFontSizeProvider);
    final readingMode = ref.watch(epubReadingModeProvider);
    final isWakelockActive = ref.watch(epubWakelockProvider);

    return Scaffold(
      appBar: _isUiVisible
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    epubAsync.value?.title ?? fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (epubAsync.value != null && epubAsync.value!.chapterCount > 0)
                    Text(
                      'Chapter ${activeChapterIndex + 1} of ${epubAsync.value!.chapterCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                ],
              ),
              actions: [
                epubAsync.when(
                  data: (doc) => IconButton(
                    icon: const Icon(LucideIcons.list),
                    tooltip: 'Table of Contents',
                    onPressed: () => _showTocSheet(context, doc, activeChapterIndex),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.type),
                  tooltip: 'Display Settings',
                  onPressed: () => _showSettingsSheet(context),
                ),
                IconButton(
                  icon: Icon(
                    isWakelockActive ? LucideIcons.zap : LucideIcons.zap_off,
                    color: isWakelockActive ? colorScheme.primary : null,
                  ),
                  tooltip: isWakelockActive ? 'Screen Awake Enabled' : 'Screen Awake Disabled',
                  onPressed: () => ref.read(epubWakelockProvider.notifier).toggle(),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.ellipsis_vertical),
                  onSelected: (value) {
                    switch (value) {
                      case 'info':
                        if (epubAsync.value != null) {
                          _showInfoSheet(context, epubAsync.value!);
                        }
                      case 'share':
                        _shareFile();
                      case 'open_external':
                        _openInExternalApp();
                    }
                  },
                  itemBuilder: (context) => [
                    if (epubAsync.value != null)
                      const PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(LucideIcons.info, size: 18),
                            SizedBox(width: 12),
                            Text('Book Details'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(LucideIcons.share_2, size: 18),
                          SizedBox(width: 12),
                          Text('Share Book'),
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
            )
          : null,
      body: epubAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Opening e-book...',
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
                Icon(LucideIcons.triangle_alert, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to open EPUB',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => ref.refresh(epubDocumentProvider(widget.filePath)),
                  icon: const Icon(LucideIcons.refresh_cw, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (doc) {
          if (doc.chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.book_x, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No readable chapters found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The EPUB archive did not contain any spine chapters.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          final chapterCount = doc.chapterCount;

          return GestureDetector(
            onTap: () {
              setState(() {
                _isUiVisible = !_isUiVisible;
              });
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: chapterCount,
              onPageChanged: (newIndex) {
                ref.read(epubActiveChapterIndexProvider.notifier).state = newIndex;
                _recordProgress(newIndex, chapterCount);
              },
              itemBuilder: (context, index) {
                final chapter = doc.chapters[index];
                return EpubChapterView(
                  chapter: chapter,
                  fontSize: fontSize,
                  readingMode: readingMode,
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _isUiVisible && epubAsync.value != null && epubAsync.value!.chapterCount > 1
          ? _buildBottomNavigationBar(context, epubAsync.value!, activeChapterIndex)
          : null,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, EpubDocument doc, int activeIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalChapters = doc.chapterCount;
    final progress = totalChapters > 0 ? ((activeIndex + 1) / totalChapters) : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevron_left),
                  tooltip: 'Previous Chapter',
                  onPressed: activeIndex > 0 ? () => _goToChapter(activeIndex - 1, totalChapters) : null,
                ),
                Expanded(
                  child: totalChapters > 1
                      ? SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: activeIndex.clamp(0, totalChapters - 1).toDouble(),
                            min: 0.0,
                            max: (totalChapters - 1).toDouble(),
                            divisions: totalChapters - 1,
                            label: 'Chapter ${activeIndex + 1}',
                            onChanged: (val) {
                              _goToChapter(val.round(), totalChapters);
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            'Chapter 1 of 1',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevron_right),
                  tooltip: 'Next Chapter',
                  onPressed: activeIndex < totalChapters - 1
                      ? () => _goToChapter(activeIndex + 1, totalChapters)
                      : null,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chapter ${activeIndex + 1} of $totalChapters',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  Text(
                    '$percent% Read',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
