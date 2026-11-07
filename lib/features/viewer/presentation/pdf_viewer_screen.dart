import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/widget_sync.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/presentation/providers/pdf_viewer_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/page_jump_dialog.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_bottom_scrubber.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_outline_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_password_dialog.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_reading_mode_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_search_bar.dart';
import 'package:docora/features/viewer/domain/models/pdf_annotation_models.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_annotation_layer.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_annotation_toolbar.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_signature_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

/// Full-featured, offline PDF Document Viewer for Docora.
/// Supports 60fps native rendering, zoom gestures, text search with highlights,
/// table of contents navigation, reading modes, screen wake-lock, and state persistence.
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    required this.filePath,
    super.key,
  });

  final String filePath;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late final PdfViewerController _pdfController;
  PdfTextSearcher? _searcher;

  PdfTextSearcher get _ensureSearcher =>
      _searcher ??= PdfTextSearcher(_pdfController);

  bool _isFullscreen = false;
  bool _isSearching = false;
  int _currentPage = 1;
  int _totalPages = 1;
  double _currentZoom = 1.0;
  List<PdfOutlineNode>? _outline;
  bool _isEncrypted = false;
  int _initialPage = 1;
  Timer? _saveDebounceTimer;

  // PDF Annotation Suite State
  bool _isAnnotating = false;
  AnnotationTool _activeTool = AnnotationTool.none;
  Color _activeColor = const Color(0xFFEAB308); // Highlighter Gold
  final Map<int, List<PdfStroke>> _pageStrokes = {};
  final Map<int, List<PdfTextAnnotation>> _pageNotes = {};
  final Map<int, List<PdfSignatureAnnotation>> _pageSignatures = {};

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _pdfController.addListener(_onControllerUpdate);
    _loadSavedReadingProgress();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _saveReadingProgressNow();
    _pdfController.removeListener(_onControllerUpdate);
    _searcher?.dispose();
    super.dispose();
  }

  Future<void> _loadSavedReadingProgress() async {
    try {
      final repo = ref.read(documentRepositoryProvider);
      final lastPage = await repo.getLastReadPage(widget.filePath);
      if (lastPage != null && lastPage > 0 && mounted) {
        setState(() {
          _initialPage = lastPage;
          _currentPage = lastPage;
        });
      }
    } on Object catch (_) {}
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    final newPage = _pdfController.pageNumber;
    final newCount = _pdfController.isReady ? _pdfController.pageCount : 1;
    final newZoom = _pdfController.currentZoom;

    if (newPage != null && newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
        _totalPages = newCount;
        _currentZoom = newZoom;
      });
      _scheduleProgressSave(newPage, newCount);
    } else if (newZoom != _currentZoom || newCount != _totalPages) {
      setState(() {
        _totalPages = newCount;
        _currentZoom = newZoom;
      });
    }
  }

  void _scheduleProgressSave(int page, int totalPages) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 800), _saveReadingProgressNow);
  }

  Future<void> _saveReadingProgressNow() async {
    try {
      final repo = ref.read(documentRepositoryProvider);
      await repo.saveReadingProgress(
        path: widget.filePath,
        pageIndex: _currentPage,
        totalPages: _totalPages,
      );
      await repo.updateDocumentPageCount(
        path: widget.filePath,
        pageCount: _totalPages,
      );
      WidgetSync.syncReadingProgress(
        filePath: widget.filePath,
        fileName: p.basename(widget.filePath),
        currentPage: _currentPage,
        totalPages: _totalPages,
      );
    } on Object catch (_) {}
  }

  void _toggleFullscreen() {
    AppMotion.subtleHaptic();
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen && _isSearching) {
        _isSearching = false;
        _searcher?.resetTextSearch();
      }
    });
  }

  Future<void> _jumpToPage() async {
    final page = await PageJumpDialog.show(
      context,
      currentPage: _currentPage,
      totalPages: _totalPages,
    );

    if (page != null && page != _currentPage && mounted) {
      await _pdfController.goToPage(pageNumber: page);
    }
  }

  Future<void> _showOutline() async {
    if (_outline == null) {
      try {
        _outline = await _pdfController.document.loadOutline();
      } on Object catch (_) {
        _outline = const [];
      }
    }

    if (mounted) {
      PdfOutlineSheet.show(
        context: context,
        outline: _outline ?? const [],
        onPageSelected: (page) {
          _pdfController.goToPage(pageNumber: page);
        },
      );
    }
  }

  void _showReadingModeSheet() {
    final currentMode = ref.read(pdfReadingModeProvider);
    PdfReadingModeSheet.show(
      context: context,
      currentMode: currentMode,
      onModeSelected: (mode) {
        ref.read(pdfReadingModeProvider.notifier).state = mode;
      },
    );
  }

  void _showInfoSheet() {
    PdfInfoSheet.show(
      context: context,
      filePath: widget.filePath,
      pageCount: _totalPages,
      isEncrypted: _isEncrypted,
    );
  }

  void _toggleAnnotationMode() {
    AppMotion.subtleHaptic();
    setState(() {
      _isAnnotating = !_isAnnotating;
      if (!_isAnnotating) {
        _activeTool = AnnotationTool.none;
      } else {
        _activeTool = AnnotationTool.pen;
      }
    });
  }

  void _undoAnnotation() {
    final strokes = _pageStrokes[_currentPage];
    if (strokes != null && strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
    }
  }

  void _clearPageAnnotations() {
    AppMotion.subtleHaptic();
    setState(() {
      _pageStrokes[_currentPage]?.clear();
      _pageNotes[_currentPage]?.clear();
      _pageSignatures[_currentPage]?.clear();
    });
  }

  Future<void> _addSignature() async {
    final strokes = await PdfSignatureDialog.show(context);
    if (strokes != null && strokes.isNotEmpty && mounted) {
      final sig = PdfSignatureAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        page: _currentPage,
        xRatio: 0.35,
        yRatio: 0.45,
        strokes: strokes,
      );
      setState(() {
        final list = _pageSignatures[_currentPage] ??= [];
        list.add(sig);
        _activeTool = AnnotationTool.none;
      });
    }
  }

  String get _resolvedPath {
    var path = widget.filePath;
    if (path.startsWith('file://')) {
      try {
        path = Uri.parse(path).toFilePath();
      } catch (_) {
        path = path.replaceFirst('file://', '');
      }
    }
    if (path.contains('%')) {
      try {
        path = Uri.decodeFull(path);
      } catch (_) {}
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final readingMode = ref.watch(pdfReadingModeProvider);
    final layoutMode = ref.watch(pdfLayoutModeProvider);
    final isWakelockActive = ref.watch(pdfWakelockProvider);

    final resolved = _resolvedPath;
    final fileName = p.basename(resolved);
    final file = File(resolved);
    if (!file.existsSync()) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(fileName),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrow_left),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.file_x, size: 56, color: colorScheme.error),
                const SizedBox(height: AppSpacing.md),
                Text('File Not Found', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.error)),
                const SizedBox(height: AppSpacing.xs),
                Text(resolved, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() => _isSearching = false);
          return;
        }
        if (_isAnnotating) {
          _toggleAnnotationMode();
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
        backgroundColor: readingMode == PdfReadingMode.dark
            ? const Color(0xFF16181D)
            : (readingMode == PdfReadingMode.sepia
                ? const Color(0xFFFBF0D9)
                : AppColors.backgroundLight),
        body: SafeArea(
          top: !_isFullscreen,
          bottom: !_isFullscreen,
          child: Stack(
            children: [
              // ── Primary Document Content Area (Positioned below AppBar) ──
              Positioned.fill(
                top: _isFullscreen ? 0 : (_isSearching ? 120 : 64),
                child: readingMode.colorFilter != null
                    ? ColorFiltered(
                        colorFilter: readingMode.colorFilter!,
                        child: _buildPdfViewer(colorScheme, readingMode, layoutMode),
                      )
                    : _buildPdfViewer(colorScheme, readingMode, layoutMode),
              ),

              // ── PDF Annotation Layer (Matches document content area) ──
              if (_isAnnotating)
                Positioned.fill(
                  top: _isFullscreen ? 0 : (_isSearching ? 120 : 64),
                  child: PdfAnnotationLayer(
                    currentPage: _currentPage,
                    activeTool: _activeTool,
                    activeColor: _activeColor,
                    pageStrokes: _pageStrokes[_currentPage] ?? const [],
                    pageNotes: _pageNotes[_currentPage] ?? const [],
                    pageSignatures: _pageSignatures[_currentPage] ?? const [],
                    onStrokesUpdated: (updated) {
                      setState(() {
                        _pageStrokes[_currentPage] = updated;
                      });
                    },
                    onNotesUpdated: (updated) {
                      setState(() {
                        _pageNotes[_currentPage] = updated;
                      });
                    },
                    onSignaturesUpdated: (updated) {
                      setState(() {
                        _pageSignatures[_currentPage] = updated;
                      });
                    },
                  ),
                ),

              // ── Minimal Top App Bar (Word Viewer matching) ──
              if (!_isFullscreen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withAlpha(50),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.arrow_left, size: 22),
                            tooltip: 'Back',
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                context.go(AppRoutes.home);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_totalPages > 1)
                                  Text(
                                    'Page $_currentPage of $_totalPages',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isSearching ? LucideIcons.x : LucideIcons.search,
                              size: 20,
                            ),
                            tooltip: 'Search',
                            onPressed: () {
                              setState(() {
                                _isSearching = !_isSearching;
                                if (_isSearching) {
                                  _ensureSearcher;
                                } else {
                                  _searcher?.resetTextSearch();
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              readingMode == PdfReadingMode.dark
                                  ? LucideIcons.sun
                                  : LucideIcons.moon,
                              size: 20,
                            ),
                            tooltip: 'Night mode',
                            onPressed: () {
                              final nextMode = readingMode == PdfReadingMode.dark
                                  ? PdfReadingMode.normal
                                  : PdfReadingMode.dark;
                              ref.read(pdfReadingModeProvider.notifier).state = nextMode;
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isAnnotating ? LucideIcons.pen_line : LucideIcons.pencil,
                              size: 20,
                              color: _isAnnotating ? colorScheme.primary : null,
                            ),
                            tooltip: _isAnnotating ? 'Close annotations' : 'Annotate PDF',
                            onPressed: _toggleAnnotationMode,
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(LucideIcons.ellipsis_vertical, size: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) async {
                              switch (val) {
                                case 'fullscreen':
                                  _toggleFullscreen();
                                case 'goto':
                                  _jumpToPage();
                                case 'outline':
                                  _showOutline();
                                case 'palette':
                                  _showReadingModeSheet();
                                case 'layout':
                                  final nextLayout =
                                      layoutMode == PdfLayoutMode.verticalContinuous
                                          ? PdfLayoutMode.horizontalSingle
                                          : PdfLayoutMode.verticalContinuous;
                                  ref.read(pdfLayoutModeProvider.notifier).state =
                                      nextLayout;
                                  _pdfController.invalidate();
                                case 'wakelock':
                                  ref.read(pdfWakelockProvider.notifier).toggle();
                                case 'info':
                                  _showInfoSheet();
                                case 'share':
                                  await Share.shareXFiles(
                                    [XFile(widget.filePath)],
                                    text: fileName,
                                  );
                                case 'open_external':
                                  await OpenFile.open(widget.filePath);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'fullscreen',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.maximize, size: 18),
                                    SizedBox(width: 12),
                                    Text('Full Screen'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'goto',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.corner_down_right, size: 18),
                                    SizedBox(width: 12),
                                    Text('Go to Page'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'outline',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.list_tree, size: 18),
                                    SizedBox(width: 12),
                                    Text('Table of Contents'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'palette',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.palette, size: 18),
                                    SizedBox(width: 12),
                                    Text('Reading Mode (Sepia / Invert)'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'layout',
                                child: Row(
                                  children: [
                                    Icon(
                                      layoutMode == PdfLayoutMode.verticalContinuous
                                          ? LucideIcons.columns_2
                                          : LucideIcons.rows_2,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      layoutMode == PdfLayoutMode.verticalContinuous
                                          ? 'Horizontal Flip Mode'
                                          : 'Continuous Scroll Mode',
                                    ),
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
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isWakelockActive
                                          ? 'Screen Awake (On)'
                                          : 'Screen Awake (Off)',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'info',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.info, size: 18),
                                    SizedBox(width: 12),
                                    Text('Document Info'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.share_2, size: 18),
                                    SizedBox(width: 12),
                                    Text('Share Document'),
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
                    ),
                  ),
                ),

              // ── In-Document Search Bar ──
              if (_isSearching && !_isFullscreen)
                Positioned(
                  top: 64,
                  left: 0,
                  right: 0,
                  child: PdfSearchBarWidget(
                    searcher: _ensureSearcher,
                    onClose: () {
                      setState(() => _isSearching = false);
                    },
                  ),
                ),

              // ── Floating Page Pill (Word Viewer matching) ──
              if (_totalPages > 1 && !_isFullscreen)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _jumpToPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(235),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outline.withAlpha(80),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.file_text,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_currentPage / $_totalPages',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── PDF Annotation Toolbar ──
              if (_isAnnotating && !_isFullscreen)
                Positioned(
                  bottom: AppSpacing.xl,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: PdfAnnotationToolbar(
                      activeTool: _activeTool,
                      activeColor: _activeColor,
                      onToolChanged: (tool) => setState(() => _activeTool = tool),
                      onColorChanged: (c) => setState(() => _activeColor = c),
                      onUndo: _undoAnnotation,
                      onClearPage: _clearPageAnnotations,
                      onAddSignature: _addSignature,
                      onClose: _toggleAnnotationMode,
                    ),
                  ),
                ),

              // ── Floating Exit-Fullscreen Button ──
              if (_isFullscreen)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleFullscreen,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(210),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.minimize_2,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer(
    ColorScheme colorScheme,
    PdfReadingMode readingMode,
    PdfLayoutMode layoutMode,
  ) {
    return PdfViewer.file(
      _resolvedPath,
      controller: _pdfController,
      initialPageNumber: _initialPage,
      passwordProvider: () async {
        setState(() => _isEncrypted = true);
        return PdfPasswordDialog.show(context);
      },
      params: PdfViewerParams(
        backgroundColor: readingMode == PdfReadingMode.dark
            ? const Color(0xFF16181D)
            : (readingMode == PdfReadingMode.sepia
                ? const Color(0xFFFBF0D9)
                : const Color(0xFFF2F4F7)),
        margin: 12.0,
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading PDF document...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        pagePaintCallbacks: [
          (page, canvas, pageRect) {
            _searcher?.pageTextMatchPaintCallback(page, canvas, pageRect);
          },
        ],
        onViewerReady: (document, controller) {
          if (mounted && _searcher == null) {
            setState(() {
              _searcher = PdfTextSearcher(_pdfController);
            });
          }
        },
        onPageChanged: (pageNumber) {
          if (pageNumber != null && mounted) {
            setState(() {
              _currentPage = pageNumber;
            });
          }
        },
        layoutPages: layoutMode == PdfLayoutMode.horizontalSingle
            ? (pages, params) {
                final height = pages.fold(
                      0.0,
                      (prev, page) => math.max(prev, page.height),
                    ) +
                    params.margin * 2;
                final pageLayouts = <Rect>[];
                double x = params.margin;
                for (final page in pages) {
                  pageLayouts.add(
                    Rect.fromLTWH(
                      x,
                      params.margin,
                      page.width,
                      page.height,
                    ),
                  );
                  x += page.width + params.margin;
                }
                return PdfPageLayout(
                  pageLayouts: pageLayouts,
                  documentSize: Size(x, height),
                );
              }
            : null,
        viewerOverlayBuilder: (context, size, handleLinkTap) => [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              handleLinkTap(details.localPosition);
              if (_isFullscreen) {
                _toggleFullscreen();
              }
            },
          ),
        ],
        errorBannerBuilder: (context, error, stackTrace, documentRef) =>
            _buildErrorWidget(context, error),
      ),
    );
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
                'Unable to Render Document',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This PDF may be corrupt or encrypted with an unsupported algorithm.',
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
                      _pdfController.invalidate();
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
