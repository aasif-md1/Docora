import 'dart:math' as math;

import 'package:docora/core/services/spreadsheet_parser_service.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Loads and parses an Excel (.xlsx, .xls) or CSV document asynchronously.
final spreadsheetDocumentProvider =
    FutureProvider.autoDispose.family<SpreadsheetDocument, String>(
        (ref, filePath) => SpreadsheetParserService.parseFile(filePath));

/// Active sheet tab index.
final spreadsheetActiveSheetIndexProvider =
    StateProvider.autoDispose<int>((ref) => 0);

/// Currently selected cell coordinate: (rowIndex, columnIndex).
final spreadsheetSelectedCellProvider =
    StateProvider.autoDispose<({int row, int col})?>((ref) => null);

/// Column sorting state: (columnIndex, isAscending).
final spreadsheetSortProvider =
    StateProvider.autoDispose<({int columnIndex, bool isAscending})?>((ref) => null);

/// In-sheet text search query.
final spreadsheetSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Active search match index.
final spreadsheetSearchMatchIndexProvider =
    StateProvider.autoDispose<int>((ref) => 0);

/// Visual reading mode (Normal, Dark, Sepia, Grayscale).
final spreadsheetReadingModeProvider =
    StateProvider.autoDispose<PdfReadingMode>((ref) => PdfReadingMode.normal);

/// Font scale multiplier (0.8x to 1.5x).
final spreadsheetFontScaleProvider =
    StateProvider.autoDispose<double>((ref) => 1.0);

/// Screen wake-lock notifier.
class SpreadsheetWakelockNotifier extends StateNotifier<bool> {
  SpreadsheetWakelockNotifier() : super(false);

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      await WakelockPlus.toggle(enable: next);
    } on Object catch (_) {}
  }

  Future<void> disable() async {
    if (state) {
      state = false;
      try {
        await WakelockPlus.disable();
      } on Object catch (_) {}
    }
  }
}

final spreadsheetWakelockProvider =
    StateNotifierProvider.autoDispose<SpreadsheetWakelockNotifier, bool>((ref) {
  final notifier = SpreadsheetWakelockNotifier();
  ref.onDispose(notifier.disable);
  return notifier;
});

/// Computes summary statistics (Count, Sum, Avg, Min, Max) for the selected column or active cell.
final spreadsheetStatsProvider =
    Provider.autoDispose.family<SpreadsheetStats, SpreadsheetSheet>((ref, sheet) {
  final selected = ref.watch(spreadsheetSelectedCellProvider);
  if (selected == null) return SpreadsheetStats.empty();

  // If top header row is selected or a cell is selected, calculate statistics for that column
  final col = selected.col;
  final numbers = <double>[];
  int count = 0;

  for (int r = 0; r < sheet.rows.length; r++) {
    final cell = sheet.getCell(r, col);
    if (cell == null || cell.isEmpty) continue;
    count++;

    final raw = cell.rawValue;
    if (raw is num) {
      numbers.add(raw.toDouble());
    } else {
      final parsed = double.tryParse(cell.value.replaceAll(',', '').trim());
      if (parsed != null) {
        numbers.add(parsed);
      }
    }
  }

  if (numbers.isEmpty) {
    return SpreadsheetStats(
      count: count,
      sum: 0,
      average: 0,
      min: 0,
      max: 0,
      hasNumeric: false,
    );
  }

  final sum = numbers.reduce((a, b) => a + b);
  final avg = sum / numbers.length;
  final min = numbers.reduce(math.min);
  final max = numbers.reduce(math.max);

  return SpreadsheetStats(
    count: count,
    sum: sum,
    average: avg,
    min: min,
    max: max,
    hasNumeric: true,
  );
});
