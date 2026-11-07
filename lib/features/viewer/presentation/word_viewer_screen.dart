import 'dart:async';
import 'dart:io';
import 'package:docora/core/services/widget_sync.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/gander_document_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Production-grade Word (.docx, .doc, .odt, .rtf) Document Viewer for Docora.
/// Powered by Gander's authentic offline WebView engine with docx-preview,
/// JSZip, and prose-doc parsers.
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
  final GlobalKey<GanderDocumentWebViewState> _ganderKey = GlobalKey<GanderDocumentWebViewState>();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isFullscreen = false;
  bool _isNightMode = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _currentMatch = 0;
  int _totalMatches = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveRecentDocument();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveRecentDocument() async {
    try {
      final repo = ref.read(documentRepositoryProvider);
      final doc = await repo.getDocumentByPath(widget.filePath);
      if (doc != null) {
        await repo.markOpened(doc.id);
      }
    } catch (_) {}
  }

  void _onPageChanged(int cur, int total) {
    if (mounted) {
      setState(() {
        _currentPage = cur;
        _totalPages = total;
      });
      try {
        final repo = ref.read(documentRepositoryProvider);
        repo.saveReadingProgress(
          path: widget.filePath,
          pageIndex: cur,
          totalPages: total,
          scrollOffset: 0,
        );
        WidgetSync.syncReadingProgress(
          filePath: widget.filePath,
          fileName: p.basename(widget.filePath),
          currentPage: cur,
          totalPages: total,
        );
      } catch (_) {}
    }
  }

  void _onSearchMatchesChanged(int cur, int total) {
    if (mounted) {
      setState(() {
        _currentMatch = cur;
        _totalMatches = total;
      });
    }
  }

  void _toggleNightMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isNightMode = !_isNightMode;
    });
    _ganderKey.currentState?.setNightMode(_isNightMode);
  }

  void _toggleFullscreen() {
    HapticFeedback.selectionClick();
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        _isSearching = false;
      }
    });
  }

  void _showGoToPageDialog() {
    final textController = TextEditingController(text: '$_currentPage');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Go to Page', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter page number (1 to $_totalPages):',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                hintText: 'Page #',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(textController.text.trim());
              if (page != null && page >= 1 && page <= _totalPages) {
                _ganderKey.currentState?.goToPage(page);
                setState(() => _currentPage = page);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _showFileInfoSheet() {
    final file = File(widget.filePath);
    final stat = file.existsSync() ? file.statSync() : null;
    final sizeStr = stat != null
        ? '${(stat.size / 1024).toStringAsFixed(1)} KB'
        : 'Unknown';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.file_text, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.basename(widget.filePath),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Format', p.extension(widget.filePath).toUpperCase().replaceAll('.', '')),
            const SizedBox(height: 8),
            _infoRow('Size', sizeStr),
            const SizedBox(height: 8),
            _infoRow('Pages', '$_totalPages'),
            const SizedBox(height: 8),
            _infoRow('Location', widget.filePath),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileName = p.basename(widget.filePath);

    return Scaffold(
      backgroundColor: _isNightMode ? const Color(0xFF0F172A) : AppColors.backgroundLight,
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        child: Stack(
          children: [
            // ── Primary Document Content Area (Maximized Viewport) ──
            Positioned.fill(
              top: _isFullscreen ? 0 : (_isSearching ? 116 : 64),
              child: GanderDocumentWebView(
                key: _ganderKey,
                filePath: widget.filePath,
                isNightMode: _isNightMode,
                onPageChanged: _onPageChanged,
                onSearchMatchesChanged: _onSearchMatchesChanged,
                onLoadingStateChanged: (loading) => setState(() => _isLoading = loading),
                onError: (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading document: $err'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
              ),
            ),

            // ── Minimal Top App Bar ──
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
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrow_left, size: 22),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
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
                            if (!_isSearching) {
                              _searchController.clear();
                              _ganderKey.currentState?.clearSearch();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isNightMode ? LucideIcons.sun : LucideIcons.moon,
                          size: 20,
                        ),
                        tooltip: 'Night mode',
                        onPressed: _toggleNightMode,
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
                              _showGoToPageDialog();
                            case 'info':
                              _showFileInfoSheet();
                            case 'share':
                              await Share.shareXFiles([XFile(widget.filePath)]);
                            case 'external':
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
                          if (_totalPages > 1)
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
                            value: 'info',
                            child: Row(
                              children: [
                                Icon(LucideIcons.info, size: 18),
                                SizedBox(width: 12),
                                Text('Document Info'),
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
                            value: 'external',
                            child: Row(
                              children: [
                                Icon(LucideIcons.external_link, size: 18),
                                SizedBox(width: 12),
                                Text('Open With Another App'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ),

            // ── Interactive In-Document Search Toolbar ──
            if (!_isFullscreen && _isSearching)
              Positioned(
                top: 64,
                left: 0,
                right: 0,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outline.withAlpha(50),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search text in document...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (q) => _ganderKey.currentState?.search(q),
                        ),
                      ),
                      if (_totalMatches > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$_currentMatch/$_totalMatches',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevron_up, size: 20),
                        tooltip: 'Previous match',
                        onPressed: () => _ganderKey.currentState?.searchPrev(),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevron_down, size: 20),
                        tooltip: 'Next match',
                        onPressed: () => _ganderKey.currentState?.searchNext(),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Floating Page Scrubber Pill ──
            if (_totalPages > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showGoToPageDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          Icon(LucideIcons.file_text, size: 14, color: colorScheme.primary),
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

            // ── Floating Exit Fullscreen Button ──
            if (_isFullscreen)
              Positioned(
                top: 24,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _toggleFullscreen,
                  backgroundColor: colorScheme.surface.withAlpha(220),
                  child: Icon(LucideIcons.minimize_2, color: colorScheme.onSurface, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
