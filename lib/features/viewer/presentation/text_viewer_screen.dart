import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:docora/features/viewer/presentation/providers/text_viewer_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/code_highlight_view.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_reading_mode_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/text_font_size_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/text_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/text_stats_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:docora/core/services/tts_service.dart';
import 'package:docora/features/viewer/presentation/widgets/tts_player_bar.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

/// Full-featured plain text, markdown, and source code viewer for Docora.
/// Features a numbered gutter, configurable typography scale, line wrapping toggle,
/// in-document text search, statistics inspector, reading modes, and copy/share actions.
class TextViewerScreen extends ConsumerStatefulWidget {
  const TextViewerScreen({
    required this.filePath,
    super.key,
  });

  final String filePath;

  @override
  ConsumerState<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends ConsumerState<TextViewerScreen> {
  bool _isSearchVisible = false;
  String _searchQuery = '';
  int _currentMatchIndex = 0;
  final List<int> _matchedLineIndices = [];
  bool _isReadingAloud = false;
  bool _isMarkdownPreview = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordProgress();
    });
  }

  void _recordProgress() {
    try {
      ref.read(documentRepositoryProvider).saveReadingProgress(
            path: widget.filePath,
            pageIndex: 1,
            totalPages: 1,
          );
    } on Object catch (_) {}
  }

  void _onSearchQueryChanged(String query, List<String> lines) {
    setState(() {
      _searchQuery = query;
      _matchedLineIndices.clear();
      _currentMatchIndex = 0;

      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].toLowerCase().contains(q)) {
            _matchedLineIndices.add(i);
          }
        }
      }
    });
  }

  void _nextMatch() {
    if (_matchedLineIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchedLineIndices.length;
    });
  }

  void _previousMatch() {
    if (_matchedLineIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchedLineIndices.length) %
              _matchedLineIndices.length;
    });
  }

  void _showStatsSheet(TextDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => TextStatsSheet(document: doc),
    );
  }

  void _showFontSizeSheet() {
    final currentSize = ref.read(textFontSizeProvider);
    final showLineNumbers = ref.read(textShowLineNumbersProvider);
    final wrapLines = ref.read(textWrapLinesProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => TextFontSizeSheet(
        currentFontSize: currentSize,
        onFontSizeChanged: (size) {
          ref.read(textFontSizeProvider.notifier).state = size;
        },
        showLineNumbers: showLineNumbers,
        onToggleLineNumbers: () {
          ref.read(textShowLineNumbersProvider.notifier).state =
              !ref.read(textShowLineNumbersProvider);
        },
        wrapLines: wrapLines,
        onToggleWrapLines: () {
          ref.read(textWrapLinesProvider.notifier).state =
              !ref.read(textWrapLinesProvider);
        },
      ),
    );
  }

  void _showReadingModeSheet() {
    PdfReadingModeSheet.show(
      context: context,
      currentMode: ref.read(textReadingModeProvider),
      onModeSelected: (mode) {
        ref.read(textReadingModeProvider.notifier).state = mode;
      },
    );
  }

  Future<void> _copyAllContent(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File content copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
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
    final resolved = _resolvedPath;
    final docAsync = ref.watch(textDocumentProvider(resolved));
    final fontSize = ref.watch(textFontSizeProvider);
    final showLineNumbers = ref.watch(textShowLineNumbersProvider);
    final wrapLines = ref.watch(textWrapLinesProvider);
    final readingMode = ref.watch(textReadingModeProvider);
    final isWakelockActive = ref.watch(textWakelockProvider);

    final fileName = p.basename(resolved);
    final ext = p.extension(resolved).toLowerCase().replaceAll('.', '').toUpperCase();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchVisible) {
          setState(() {
            _isSearchVisible = false;
            _searchQuery = '';
          });
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        titleSpacing: 0,
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
                ext.isNotEmpty ? ext : 'TXT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (docAsync.valueOrNull?.isMarkdown == true)
            IconButton(
              icon: Icon(
                _isMarkdownPreview ? LucideIcons.code : LucideIcons.file_text,
                size: 20,
              ),
              tooltip: _isMarkdownPreview ? 'View Raw Source' : 'View Markdown Preview',
              onPressed: () {
                AppMotion.subtleHaptic();
                setState(() => _isMarkdownPreview = !_isMarkdownPreview);
              },
            ),
          IconButton(
            icon: Icon(
              _isSearchVisible ? LucideIcons.search_x : LucideIcons.search,
              size: 20,
            ),
            tooltip: 'Search text',
            onPressed: () {
              AppMotion.subtleHaptic();
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _matchedLineIndices.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.sun_moon, size: 20),
            tooltip: 'Reading mode',
            onPressed: _showReadingModeSheet,
          ),
          IconButton(
            icon: Icon(
              _isReadingAloud ? LucideIcons.volume_x : LucideIcons.volume_2,
              size: 20,
              color: _isReadingAloud ? colorScheme.primary : null,
            ),
            tooltip: _isReadingAloud ? 'Stop Read Aloud' : 'Read Aloud (TTS)',
            onPressed: () {
              AppMotion.subtleHaptic();
              final doc = docAsync.valueOrNull;
              setState(() => _isReadingAloud = !_isReadingAloud);
              if (_isReadingAloud && doc != null) {
                ref.read(ttsServiceProvider).speak(doc.content);
              } else {
                ref.read(ttsServiceProvider).stop();
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings_2, size: 20),
            tooltip: 'View settings',
            onPressed: _showFontSizeSheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsis_vertical, size: 20),
            onSelected: (val) {
              final doc = docAsync.valueOrNull;
              switch (val) {
                case 'stats':
                  if (doc != null) _showStatsSheet(doc);
                case 'copy':
                  if (doc != null) _copyAllContent(doc.content);
                case 'wakelock':
                  ref.read(textWakelockProvider.notifier).toggle();
                case 'share':
                  _shareFile();
                case 'open_external':
                  _openExternal();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 18),
                    SizedBox(width: 12),
                    Text('File Details & Stats'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(LucideIcons.copy, size: 18),
                    SizedBox(width: 12),
                    Text('Copy All Text'),
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
                    Text(isWakelockActive ? 'Disable Screen Awake' : 'Keep Screen Awake'),
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
                'Reading file content...',
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
                  'Failed to load text file',
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
                  onPressed: () => ref.refresh(textDocumentProvider(widget.filePath)),
                  icon: const Icon(LucideIcons.refresh_cw, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (doc) => Stack(
          children: [
            Column(
              children: [
                // Search Bar
                if (_isSearchVisible)
                  TextSearchBar(
                    totalMatches: _matchedLineIndices.length,
                    currentMatchIndex: _currentMatchIndex,
                    onQueryChanged: (q) => _onSearchQueryChanged(q, doc.lines),
                    onPreviousMatch: _previousMatch,
                    onNextMatch: _nextMatch,
                    onClose: () {
                      setState(() {
                        _isSearchVisible = false;
                        _searchQuery = '';
                        _matchedLineIndices.clear();
                      });
                    },
                  ),

                // Code & Text View or Markdown Preview
                Expanded(
                  child: (doc.isMarkdown && _isMarkdownPreview)
                      ? Markdown(
                          data: doc.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontSize: fontSize,
                            ),
                            h1: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            h2: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            h3: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            code: TextStyle(
                              fontFamily: 'monospace',
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: colorScheme.primary,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withAlpha(120),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withAlpha(60),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        )
                      : CodeHighlightView(
                          document: doc,
                          fontSize: fontSize,
                          showLineNumbers: showLineNumbers,
                          wrapLines: wrapLines,
                          searchQuery: _searchQuery,
                          currentMatchLine: _matchedLineIndices.isNotEmpty &&
                                  _currentMatchIndex < _matchedLineIndices.length
                              ? _matchedLineIndices[_currentMatchIndex]
                              : null,
                          readingMode: readingMode,
                        ),
                ),

                // Bottom status bar (lines, words, encoding, language)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(60),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${doc.lineCount} lines',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: colorScheme.outlineVariant),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${doc.wordCount} words',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${doc.encodingName} • ${doc.languageLabel}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isReadingAloud)
              Positioned(
                bottom: 48,
                left: 20,
                right: 20,
                child: Center(
                  child: TtsPlayerBar(
                    onClose: () {
                      setState(() => _isReadingAloud = false);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}
