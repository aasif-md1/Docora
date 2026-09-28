import 'dart:async';
import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/presentation/providers/word_viewer_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_font_scale_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_renderer_widget.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_toc_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_reading_mode_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Full-featured, offline Word (.docx and .doc) Document Viewer for Docora.
/// Renders structured OpenXML AST into rich Flutter widgets with real typography scale,
/// inline images, tables, full-text search, Table of Contents, and dynamic font zoom.
class WordViewerScreen extends ConsumerStatefulWidget {
  const WordViewerScreen({
    required this.filePath,
    super.key,
  });

  final String filePath;

  @override
  ConsumerState<WordViewerScreen> createState() => _WordViewerScreenState();
}

class _WordViewerScreenState extends ConsumerState<WordViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _blockKeys = [];

  bool _isFullscreen = false;
  bool _isSearching = false;
  String _searchQuery = '';
  int _currentMatchIndex = 0;
  final List<int> _matchedBlockIndices = [];

  Timer? _scrollDebounceTimer;
  bool _hasRestoredScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _saveScrollPositionNow();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 600), _saveScrollPositionNow);
  }

  Future<void> _restoreScrollPosition(DocxDocument doc) async {
    if (_hasRestoredScroll) return;
    _hasRestoredScroll = true;

    try {
      final repo = ref.read(documentRepositoryProvider);
      final lastPage = await repo.getLastReadPage(widget.filePath);
      if (!mounted) return;
      if (lastPage != null && lastPage > 0) {
        // Find corresponding block index or scroll offset
        if (lastPage < doc.blocks.length && lastPage < _blockKeys.length) {
          final targetContext = _blockKeys[lastPage].currentContext;
          if (targetContext != null && targetContext.mounted) {
            Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    } on Object catch (_) {}
  }

  Future<void> _saveScrollPositionNow() async {
    try {
      final repo = ref.read(documentRepositoryProvider);
      final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      await repo.saveReadingProgress(
        path: widget.filePath,
        pageIndex: 1,
        totalPages: 1,
        scrollOffset: offset,
      );
    } on Object catch (_) {}
  }

  void _ensureBlockKeys(int count) {
    while (_blockKeys.length < count) {
      _blockKeys.add(GlobalKey());
    }
  }

  void _onSearchChanged(String query, DocxDocument doc) {
    setState(() {
      _searchQuery = query.trim();
      _matchedBlockIndices.clear();
      _currentMatchIndex = 0;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        for (int i = 0; i < doc.blocks.length; i++) {
          final block = doc.blocks[i];
          if (block is DocxParagraphBlock) {
            if (block.plainText.toLowerCase().contains(q)) {
              _matchedBlockIndices.add(i);
            }
          } else if (block is DocxTableBlock) {
            for (final row in block.rows) {
              for (final cell in row.cells) {
                if (cell.plainText.toLowerCase().contains(q)) {
                  _matchedBlockIndices.add(i);
                  break;
                }
              }
            }
          }
        }

        if (_matchedBlockIndices.isNotEmpty) {
          _scrollToBlock(_matchedBlockIndices.first);
        }
      }
    });
  }

  void _goToNextMatch() {
    if (_matchedBlockIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchedBlockIndices.length;
      _scrollToBlock(_matchedBlockIndices[_currentMatchIndex]);
    });
  }

  void _goToPrevMatch() {
    if (_matchedBlockIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchedBlockIndices.length) %
          _matchedBlockIndices.length;
      _scrollToBlock(_matchedBlockIndices[_currentMatchIndex]);
    });
  }

  void _scrollToBlock(int blockIndex) {
    if (blockIndex < _blockKeys.length) {
      final ctx = _blockKeys[blockIndex].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    }
  }

  void _toggleFullscreen() {
    AppMotion.subtleHaptic();
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen && _isSearching) {
        _isSearching = false;
        _searchQuery = '';
      }
    });
  }

  Color _resolveBackgroundColor(PdfReadingMode mode, ColorScheme colorScheme) {
    switch (mode) {
      case PdfReadingMode.dark:
        return const Color(0xFF121212);
      case PdfReadingMode.sepia:
        return const Color(0xFFFBF0D9);
      case PdfReadingMode.grayscale:
        return Colors.white;
      case PdfReadingMode.normal:
        return colorScheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final readingMode = ref.watch(wordReadingModeProvider);
    final fontScale = ref.watch(wordFontScaleProvider);
    final isWakelockActive = ref.watch(wordWakelockProvider);
    final docAsync = ref.watch(wordDocumentProvider(widget.filePath));

    final fileName = p.basename(widget.filePath);
    final bgColor = _resolveBackgroundColor(readingMode, colorScheme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
            _matchedBlockIndices.clear();
          });
          return;
        }
        if (_isFullscreen) {
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
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Main Document Body
          docAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Opening Word Document...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            error: (err, _) => _buildErrorWidget(context, err),
            data: (doc) {
              _ensureBlockKeys(doc.blocks.length);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _restoreScrollPosition(doc);
              });

              final mediaQuery = MediaQuery.of(context);
              final topPadding = _isFullscreen
                  ? (mediaQuery.padding.top + AppSpacing.md)
                  : (_isSearching
                      ? (mediaQuery.padding.top + kToolbarHeight * 2 + AppSpacing.md)
                      : (mediaQuery.padding.top + kToolbarHeight + AppSpacing.md));
              final bottomPadding = mediaQuery.padding.bottom + AppSpacing.xl;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _toggleFullscreen,
                child: DocxRendererWidget(
                  document: doc,
                  fontScale: fontScale,
                  readingMode: readingMode,
                  searchQuery: _searchQuery,
                  activeMatchIndex: _currentMatchIndex,
                  blockKeys: _blockKeys,
                  topPadding: topPadding,
                  bottomPadding: bottomPadding,
                ),
              );
            },
          ),

          // 2. Animated Top AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              offset: _isFullscreen ? const Offset(0, -1) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isFullscreen ? 0.0 : 1.0,
                child: AppBar(
                  backgroundColor: theme.colorScheme.surface.withAlpha(230),
                  surfaceTintColor: Colors.transparent,
                  elevation: 2,
                  leading: IconButton(
                    icon: const Icon(LucideIcons.arrow_left),
                    tooltip: 'Back',
                    onPressed: () {
                      if (_isSearching) {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _matchedBlockIndices.clear();
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      docAsync.maybeWhen(
                        data: (doc) => Text(
                          '${doc.wordCount} words • ${doc.estimatedReadingMinutes} min read',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  actions: [
                    // Search toggle
                    IconButton(
                      icon: Icon(
                        _isSearching ? LucideIcons.search_x : LucideIcons.search,
                      ),
                      tooltip: _isSearching ? 'Close search' : 'Search text',
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchQuery = '';
                            _matchedBlockIndices.clear();
                          }
                        });
                      },
                    ),

                    // Font scaling
                    IconButton(
                      icon: const Icon(LucideIcons.type),
                      tooltip: 'Text size',
                      onPressed: () {
                        DocxFontScaleSheet.show(
                          context: context,
                          currentScale: fontScale,
                          onScaleChanged: (scale) {
                            ref.read(wordFontScaleProvider.notifier).state = scale;
                          },
                        );
                      },
                    ),

                    // Reading mode
                    IconButton(
                      icon: const Icon(LucideIcons.palette),
                      tooltip: 'Reading mode',
                      onPressed: () {
                        PdfReadingModeSheet.show(
                          context: context,
                          currentMode: readingMode,
                          onModeSelected: (mode) {
                            ref.read(wordReadingModeProvider.notifier).state = mode;
                          },
                        );
                      },
                    ),

                    // Overflow Menu
                    PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.ellipsis_vertical),
                      tooltip: 'More options',
                      onSelected: (val) {
                        final doc = docAsync.valueOrNull;
                        switch (val) {
                          case 'toc':
                            if (doc != null) {
                              DocxTocSheet.show(
                                context: context,
                                headings: doc.headings,
                                onHeadingSelected: _scrollToBlock,
                              );
                            }
                          case 'info':
                            if (doc != null) {
                              DocxInfoSheet.show(
                                context: context,
                                filePath: widget.filePath,
                                document: doc,
                              );
                            }
                          case 'wakelock':
                            ref.read(wordWakelockProvider.notifier).toggle();
                          case 'fullscreen':
                            _toggleFullscreen();
                          case 'share':
                            Share.shareXFiles(
                              [XFile(widget.filePath)],
                              text: fileName,
                            );
                          case 'open_external':
                            OpenFile.open(widget.filePath);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'toc',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.list_tree,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              const Text('Table of Contents'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              const Text('Document Info'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'wakelock',
                          child: Row(
                            children: [
                              Icon(
                                isWakelockActive
                                    ? LucideIcons.eye
                                    : LucideIcons.eye_off,
                                size: 20,
                                color: isWakelockActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(isWakelockActive
                                  ? 'Keep Screen Awake (On)'
                                  : 'Keep Screen Awake (Off)'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'fullscreen',
                          child: Row(
                            children: [
                              Icon(
                                _isFullscreen
                                    ? LucideIcons.minimize
                                    : LucideIcons.maximize,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(_isFullscreen
                                  ? 'Exit Fullscreen'
                                  : 'Enter Fullscreen'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.share_2,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              const Text('Share Document'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'open_external',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.external_link,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              const Text('Open in External App'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Search Bar Overlay
          if (_isSearching && !_isFullscreen)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: docAsync.maybeWhen(
                data: (doc) => DocxSearchBarWidget(
                  totalMatches: _matchedBlockIndices.length,
                  currentMatchIndex: _currentMatchIndex,
                  onSearchChanged: (q) => _onSearchChanged(q, doc),
                  onNextMatch: _goToNextMatch,
                  onPrevMatch: _goToPrevMatch,
                  onClose: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _matchedBlockIndices.clear();
                    });
                  },
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: DocoraCard(
          variant: DocoraCardVariant.elevated,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.triangle_alert,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to Render Word Document',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The document structure may be corrupt or encrypted with unsupported protection.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DocoraButton(
                    label: 'Open Externally',
                    icon: LucideIcons.external_link,
                    variant: DocoraButtonVariant.outlined,
                    size: DocoraButtonSize.small,
                    onPressed: () => OpenFile.open(widget.filePath),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  DocoraButton(
                    label: 'Retry',
                    icon: LucideIcons.refresh_cw,
                    size: DocoraButtonSize.small,
                    onPressed: () {
                      ref.invalidate(wordDocumentProvider(widget.filePath));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
