import 'dart:io';

import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:docora/features/viewer/presentation/providers/spreadsheet_providers.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_reading_mode_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_formula_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_grid_widget.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_sheet_tabs.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_stats_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Full-featured, offline Excel (.xlsx, .xls) and CSV/TSV Spreadsheet Viewer for Docora.
/// Features a synchronized 2D grid with pinned sticky row/col headers, live formula bar,
/// column sorting, instant statistical aggregation, in-sheet text search, multi-sheet tabs,
/// 4 reading modes, and CSV export.
class SpreadsheetViewerScreen extends ConsumerStatefulWidget {
  const SpreadsheetViewerScreen({
    required this.filePath,
    super.key,
  });

  final String filePath;

  @override
  ConsumerState<SpreadsheetViewerScreen> createState() => _SpreadsheetViewerScreenState();
}

class _SpreadsheetViewerScreenState extends ConsumerState<SpreadsheetViewerScreen> {
  bool _isSearchVisible = false;
  String _searchQuery = '';
  int _currentMatchIndex = 0;
  final List<({int row, int col})> _searchMatches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordInitialProgress();
    });
  }

  void _recordInitialProgress() {
    try {
      ref.read(documentRepositoryProvider).saveReadingProgress(
            path: widget.filePath,
            pageIndex: 1,
            totalPages: 1,
          );
    } on Object catch (_) {}
  }

  void _onSearchQueryChanged(String query, SpreadsheetSheet sheet) {
    setState(() {
      _searchQuery = query;
      _searchMatches.clear();
      _currentMatchIndex = 0;

      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        for (int r = 0; r < sheet.rowCount; r++) {
          for (int c = 0; c < sheet.columnCount; c++) {
            final cell = sheet.getCell(r, c);
            if (cell != null && cell.value.toLowerCase().contains(q)) {
              _searchMatches.add((row: r, col: c));
            }
          }
        }
        if (_searchMatches.isNotEmpty) {
          ref.read(spreadsheetSelectedCellProvider.notifier).state =
              _searchMatches.first;
        }
      }
    });
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      ref.read(spreadsheetSelectedCellProvider.notifier).state =
          _searchMatches[_currentMatchIndex];
    });
  }

  void _previousMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
      ref.read(spreadsheetSelectedCellProvider.notifier).state =
          _searchMatches[_currentMatchIndex];
    });
  }

  void _showInfoSheet(SpreadsheetDocument doc, int activeSheetIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => SpreadsheetInfoSheet(
        document: doc,
        activeSheetIndex: activeSheetIndex,
      ),
    );
  }

  void _showReadingModeSheet() {
    PdfReadingModeSheet.show(
      context: context,
      currentMode: ref.read(spreadsheetReadingModeProvider),
      onModeSelected: (mode) {
        ref.read(spreadsheetReadingModeProvider.notifier).state = mode;
      },
    );
  }

  void _showFontScaleDialog() {
    final currentScale = ref.read(spreadsheetFontScaleProvider);
    final scales = [0.8, 0.9, 1.0, 1.1, 1.25, 1.5];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text Zoom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: scales.map((scale) {
            final percent = (scale * 100).toInt();
            return ListTile(
              title: Text('$percent%'),
              trailing: currentScale == scale
                  ? Icon(
                      LucideIcons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                ref.read(spreadsheetFontScaleProvider.notifier).state = scale;
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportActiveSheetAsCsv(SpreadsheetSheet sheet) async {
    try {
      final buffer = StringBuffer();
      for (int r = 0; r < sheet.rowCount; r++) {
        final rowValues = <String>[];
        for (int c = 0; c < sheet.columnCount; c++) {
          final val = sheet.getCell(r, c)?.value ?? '';
          if (val.contains(',') || val.contains('"') || val.contains('\n')) {
            rowValues.add('"${val.replaceAll('"', '""')}"');
          } else {
            rowValues.add(val);
          }
        }
        buffer.writeln(rowValues.join(','));
      }

      final dir = await getTemporaryDirectory();
      final cleanSheetName = sheet.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final exportPath = p.join(dir.path, '${cleanSheetName}_export.csv');
      final file = File(exportPath);
      await file.writeAsString(buffer.toString());

      if (!mounted) return;
      await Share.shareXFiles([XFile(exportPath)], text: '${sheet.name} (CSV Export)');
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export sheet: $e')),
      );
    }
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
    final docAsync = ref.watch(spreadsheetDocumentProvider(widget.filePath));
    final activeSheetIndex = ref.watch(spreadsheetActiveSheetIndexProvider);
    final selectedCell = ref.watch(spreadsheetSelectedCellProvider);
    final sortState = ref.watch(spreadsheetSortProvider);
    final readingMode = ref.watch(spreadsheetReadingModeProvider);
    final fontScale = ref.watch(spreadsheetFontScaleProvider);
    final isWakelockActive = ref.watch(spreadsheetWakelockProvider);

    final fileName = p.basename(widget.filePath);
    final ext = p.extension(widget.filePath).toLowerCase().replaceAll('.', '').toUpperCase();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchVisible) {
          setState(() {
            _isSearchVisible = false;
            _searchQuery = '';
            _searchMatches.clear();
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
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () {
            if (_isSearchVisible) {
              setState(() {
                _isSearchVisible = false;
                _searchQuery = '';
                _searchMatches.clear();
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
            tooltip: 'Search',
            onPressed: () {
              AppMotion.subtleHaptic();
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _searchMatches.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.sun_moon, size: 20),
            tooltip: 'Reading Mode',
            onPressed: _showReadingModeSheet,
          ),
          IconButton(
            icon: const Icon(LucideIcons.zoom_in, size: 20),
            tooltip: 'Text Zoom',
            onPressed: _showFontScaleDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsis_vertical, size: 20),
            onSelected: (val) {
              final doc = docAsync.valueOrNull;
              switch (val) {
                case 'info':
                  if (doc != null) _showInfoSheet(doc, activeSheetIndex);
                case 'wakelock':
                  ref.read(spreadsheetWakelockProvider.notifier).toggle();
                case 'export':
                  if (doc != null && doc.sheets.isNotEmpty) {
                    final sheet = doc.sheets[activeSheetIndex];
                    _exportActiveSheetAsCsv(sheet);
                  }
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
                    Text('Document Info'),
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
                value: 'export',
                child: Row(
                  children: [
                    Icon(LucideIcons.download, size: 18),
                    SizedBox(width: 12),
                    Text('Export Sheet as CSV'),
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
                'Parsing spreadsheet data...',
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
                  'Failed to load spreadsheet',
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
                  onPressed: () => ref.refresh(spreadsheetDocumentProvider(widget.filePath)),
                  icon: const Icon(LucideIcons.refresh_cw, size: 16),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (doc) {
          if (doc.sheets.isEmpty) {
            return const Center(child: Text('No sheets found in this workbook.'));
          }

          final safeSheetIndex = activeSheetIndex.clamp(0, doc.sheets.length - 1);
          final currentSheet = doc.sheets[safeSheetIndex];
          final stats = ref.watch(spreadsheetStatsProvider(currentSheet));

          SpreadsheetCell? activeCell;
          if (selectedCell != null) {
            activeCell = currentSheet.getCell(selectedCell.row, selectedCell.col);
          }

          return Column(
            children: [
              // Search Bar
              if (_isSearchVisible)
                SpreadsheetSearchBar(
                  totalMatches: _searchMatches.length,
                  currentMatchIndex: _currentMatchIndex,
                  onQueryChanged: (q) => _onSearchQueryChanged(q, currentSheet),
                  onPreviousMatch: _previousMatch,
                  onNextMatch: _nextMatch,
                  onClose: () {
                    setState(() {
                      _isSearchVisible = false;
                      _searchQuery = '';
                      _searchMatches.clear();
                    });
                  },
                ),
              // Pinned Formula Bar
              SpreadsheetFormulaBar(
                selectedCell: activeCell,
              ),
              // 2D Scrollable Grid
              Expanded(
                child: Stack(
                  children: [
                    SpreadsheetGridWidget(
                      sheet: currentSheet,
                      selectedCell: selectedCell,
                      onCellSelected: (coord) {
                        AppMotion.subtleHaptic();
                        ref.read(spreadsheetSelectedCellProvider.notifier).state = coord;
                      },
                      sortState: sortState,
                      onSortColumn: (col) {
                        AppMotion.subtleHaptic();
                        if (sortState?.columnIndex == col) {
                          if (sortState!.isAscending) {
                            ref.read(spreadsheetSortProvider.notifier).state =
                                (columnIndex: col, isAscending: false);
                          } else {
                            ref.read(spreadsheetSortProvider.notifier).state = null;
                          }
                        } else {
                          ref.read(spreadsheetSortProvider.notifier).state =
                              (columnIndex: col, isAscending: true);
                        }
                      },
                      searchQuery: _searchQuery,
                      currentMatchCell: _searchMatches.isNotEmpty &&
                              _currentMatchIndex < _searchMatches.length
                          ? _searchMatches[_currentMatchIndex]
                          : null,
                      readingMode: readingMode,
                      fontScale: fontScale,
                    ),
                    // Floating Bottom Stats Bar
                    if (stats.count > 0)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SpreadsheetStatsBar(stats: stats),
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom Multi-Sheet Tabs
              SpreadsheetSheetTabs(
                sheetNames: doc.sheetNames,
                currentIndex: safeSheetIndex,
                onSheetSelected: (index) {
                  AppMotion.subtleHaptic();
                  ref.read(spreadsheetActiveSheetIndexProvider.notifier).state = index;
                  ref.read(spreadsheetSelectedCellProvider.notifier).state = null;
                  ref.read(spreadsheetSortProvider.notifier).state = null;
                  if (_searchQuery.isNotEmpty) {
                    _onSearchQueryChanged(_searchQuery, doc.sheets[index]);
                  }
                },
              ),
            ],
          );
        },
      ),
    ));
  }
}
