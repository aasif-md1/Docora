import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// 2D Synchronized high-performance spreadsheet grid with sticky headers,
/// column sorting, active cell selection, and search query highlighting.
class SpreadsheetGridWidget extends StatefulWidget {
  const SpreadsheetGridWidget({
    required this.sheet,
    required this.selectedCell,
    required this.onCellSelected,
    this.sortState,
    this.onSortColumn,
    this.searchQuery = '',
    this.currentMatchCell,
    this.readingMode = PdfReadingMode.normal,
    this.fontScale = 1.0,
    super.key,
  });

  final SpreadsheetSheet sheet;
  final ({int row, int col})? selectedCell;
  final ValueChanged<({int row, int col})> onCellSelected;
  final ({int columnIndex, bool isAscending})? sortState;
  final ValueChanged<int>? onSortColumn;
  final String searchQuery;
  final ({int row, int col})? currentMatchCell;
  final PdfReadingMode readingMode;
  final double fontScale;

  @override
  State<SpreadsheetGridWidget> createState() => _SpreadsheetGridWidgetState();
}

class _SpreadsheetGridWidgetState extends State<SpreadsheetGridWidget> {
  final ScrollController _hBodyController = ScrollController();
  final ScrollController _hHeaderController = ScrollController();
  final ScrollController _vBodyController = ScrollController();
  final ScrollController _vRowController = ScrollController();

  bool _isSyncingH = false;
  bool _isSyncingV = false;

  static const double _rowHeight = 36.0;
  static const double _rowNumberWidth = 48.0;
  static const double _colWidth = 110.0;

  @override
  void initState() {
    super.initState();
    _hBodyController.addListener(_syncHorizontal);
    _hHeaderController.addListener(_syncHorizontalHeader);
    _vBodyController.addListener(_syncVertical);
    _vRowController.addListener(_syncVerticalRow);
  }

  @override
  void didUpdateWidget(SpreadsheetGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMatchCell != null &&
        widget.currentMatchCell != oldWidget.currentMatchCell) {
      _scrollToCell(widget.currentMatchCell!.row, widget.currentMatchCell!.col);
    }
  }

  void _scrollToCell(int row, int col) {
    final targetX = col * _colWidth;
    final targetY = row * _rowHeight;

    if (_hBodyController.hasClients) {
      final currentX = _hBodyController.offset;
      final viewWidth = _hBodyController.position.viewportDimension;
      if (targetX < currentX || targetX + _colWidth > currentX + viewWidth) {
        _hBodyController.animateTo(
          (targetX - viewWidth / 3).clamp(0.0, _hBodyController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }

    if (_vBodyController.hasClients) {
      final currentY = _vBodyController.offset;
      final viewHeight = _vBodyController.position.viewportDimension;
      if (targetY < currentY || targetY + _rowHeight > currentY + viewHeight) {
        _vBodyController.animateTo(
          (targetY - viewHeight / 3).clamp(0.0, _vBodyController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _syncHorizontal() {
    if (_isSyncingH || !_hHeaderController.hasClients) return;
    _isSyncingH = true;
    _hHeaderController.jumpTo(_hBodyController.offset);
    _isSyncingH = false;
  }

  void _syncHorizontalHeader() {
    if (_isSyncingH || !_hBodyController.hasClients) return;
    _isSyncingH = true;
    _hBodyController.jumpTo(_hHeaderController.offset);
    _isSyncingH = false;
  }

  void _syncVertical() {
    if (_isSyncingV || !_vRowController.hasClients) return;
    _isSyncingV = true;
    _vRowController.jumpTo(_vBodyController.offset);
    _isSyncingV = false;
  }

  void _syncVerticalRow() {
    if (_isSyncingV || !_vBodyController.hasClients) return;
    _isSyncingV = true;
    _vBodyController.jumpTo(_vRowController.offset);
    _isSyncingV = false;
  }

  @override
  void dispose() {
    _hBodyController.dispose();
    _hHeaderController.dispose();
    _vBodyController.dispose();
    _vRowController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return const Color(0xFF14141A);
      case PdfReadingMode.sepia:
        return const Color(0xFFFBF0D9);
      case PdfReadingMode.grayscale:
        return Colors.white;
      case PdfReadingMode.normal:
        return colorScheme.surface;
    }
  }

  Color _getHeaderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return const Color(0xFF1E1E26);
      case PdfReadingMode.sepia:
        return const Color(0xFFEFE2C6);
      case PdfReadingMode.grayscale:
        return const Color(0xFFECECEC);
      case PdfReadingMode.normal:
        return colorScheme.surfaceContainer;
    }
  }

  Color _getBorderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return Colors.white.withAlpha(25);
      case PdfReadingMode.sepia:
        return const Color(0xFFDCC8A7);
      case PdfReadingMode.grayscale:
        return Colors.grey.shade300;
      case PdfReadingMode.normal:
        return colorScheme.outlineVariant.withAlpha(60);
    }
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.readingMode) {
      case PdfReadingMode.dark:
        return Colors.white70;
      case PdfReadingMode.sepia:
        return const Color(0xFF382D1F);
      case PdfReadingMode.grayscale:
        return Colors.black87;
      case PdfReadingMode.normal:
        return colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final rowCount = sheet.rowCount;
    final colCount = sheet.columnCount;
    final colorScheme = Theme.of(context).colorScheme;

    if (rowCount == 0 || colCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sheet,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Sheet is empty',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    final bgColor = _getBackgroundColor(context);
    final headerColor = _getHeaderColor(context);
    final borderColor = _getBorderColor(context);
    final textColor = _getTextColor(context);

    // Apply column sorting if active
    final sortedRowIndices = List<int>.generate(rowCount, (i) => i);
    if (widget.sortState != null) {
      final col = widget.sortState!.columnIndex;
      final asc = widget.sortState!.isAscending;
      sortedRowIndices.sort((a, b) {
        final cellA = sheet.getCell(a, col)?.value ?? '';
        final cellB = sheet.getCell(b, col)?.value ?? '';

        final numA = double.tryParse(cellA);
        final numB = double.tryParse(cellB);
        if (numA != null && numB != null) {
          return asc ? numA.compareTo(numB) : numB.compareTo(numA);
        }
        return asc ? cellA.compareTo(cellB) : cellB.compareTo(cellA);
      });
    }

    return ColoredBox(
      color: bgColor,
      child: Column(
        children: [
          // Sticky Top Row (Corner + Column Headers)
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                // Corner "fx" Header
                Container(
                  width: _rowNumberWidth,
                  height: _rowHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: headerColor,
                    border: Border(
                      right: BorderSide(color: borderColor),
                      bottom: BorderSide(color: borderColor, width: 1.5),
                    ),
                  ),
                  child: Text(
                    'fx',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      fontSize: 12 * widget.fontScale,
                      color: textColor.withAlpha(150),
                    ),
                  ),
                ),
                // Horizontal Column Headers (A, B, C...)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hHeaderController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: List.generate(colCount, (col) {
                        final isSelectedCol = widget.selectedCell?.col == col;
                        final isSortedCol = widget.sortState?.columnIndex == col;
                        final headerName = columnNumberToLetters(col);

                        return InkWell(
                          onTap: () => widget.onSortColumn?.call(col),
                          child: Container(
                            width: _colWidth,
                            height: _rowHeight,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelectedCol
                                  ? colorScheme.primaryContainer.withAlpha(100)
                                  : headerColor,
                              border: Border(
                                right: BorderSide(color: borderColor),
                                bottom: BorderSide(color: borderColor, width: 1.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  headerName,
                                  style: TextStyle(
                                    fontWeight: isSelectedCol || isSortedCol
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 12 * widget.fontScale,
                                    color: isSelectedCol
                                        ? colorScheme.primary
                                        : textColor,
                                  ),
                                ),
                                if (isSortedCol) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    widget.sortState!.isAscending
                                        ? LucideIcons.arrow_up
                                        : LucideIcons.arrow_down,
                                    size: 12,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Grid (Row Headers + Cells)
          Expanded(
            child: Row(
              children: [
                // Sticky Left Row Numbers (1, 2, 3...)
                SizedBox(
                  width: _rowNumberWidth,
                  child: ListView.builder(
                    controller: _vRowController,
                    physics: const ClampingScrollPhysics(),
                    itemCount: rowCount,
                    itemExtent: _rowHeight,
                    itemBuilder: (context, index) {
                      final originalRow = sortedRowIndices[index];
                      final isSelectedRow = widget.selectedCell?.row == originalRow;

                      return Container(
                        height: _rowHeight,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelectedRow
                              ? colorScheme.primaryContainer.withAlpha(100)
                              : headerColor,
                          border: Border(
                            right: BorderSide(color: borderColor, width: 1.5),
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: isSelectedRow ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11 * widget.fontScale,
                            color: isSelectedRow
                                ? colorScheme.primary
                                : textColor.withAlpha(180),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 2D Scrollable Cell Matrix
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hBodyController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: colCount * _colWidth,
                      child: ListView.builder(
                        controller: _vBodyController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: rowCount,
                        itemExtent: _rowHeight,
                        itemBuilder: (context, index) {
                          final originalRow = sortedRowIndices[index];
                          final isAlternate = index.isOdd;

                          return Row(
                            children: List.generate(colCount, (col) {
                              final cell = sheet.getCell(originalRow, col);
                              final isSelected = widget.selectedCell?.row == originalRow &&
                                  widget.selectedCell?.col == col;
                              final isQueryMatch = widget.searchQuery.isNotEmpty &&
                                  cell != null &&
                                  cell.value.toLowerCase().contains(
                                        widget.searchQuery.toLowerCase(),
                                      );
                              final isCurrentMatch = widget.currentMatchCell?.row == originalRow &&
                                  widget.currentMatchCell?.col == col;

                              final cellValue = cell?.value ?? '';
                              final isNumeric = cell?.isNumeric ?? false;

                              return GestureDetector(
                                onTap: () => widget.onCellSelected(
                                  (row: originalRow, col: col),
                                ),
                                child: Container(
                                  width: _colWidth,
                                  height: _rowHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: isNumeric
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: isCurrentMatch
                                        ? Colors.amber.withAlpha(130)
                                        : isQueryMatch
                                            ? Colors.amber.withAlpha(60)
                                            : isSelected
                                                ? colorScheme.primaryContainer.withAlpha(70)
                                                : (isAlternate
                                                    ? (Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.white.withAlpha(5)
                                                        : Colors.black.withAlpha(5))
                                                    : Colors.transparent),
                                    border: isSelected
                                        ? Border.all(
                                            color: colorScheme.primary,
                                            width: 2,
                                          )
                                        : Border(
                                            right: BorderSide(color: borderColor),
                                            bottom: BorderSide(color: borderColor),
                                          ),
                                  ),
                                  child: Text(
                                    cellValue,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12 * widget.fontScale,
                                      color: textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
