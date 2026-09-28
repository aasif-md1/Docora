import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Parameters passed to background compute isolate for spreadsheet parsing.
class _SpreadsheetParseParams {
  const _SpreadsheetParseParams({
    required this.bytes,
    required this.filePath,
    required this.fileName,
  });

  final Uint8List bytes;
  final String filePath;
  final String fileName;
}

/// Service for parsing Excel (.xlsx, .xls) and Delimited (.csv, .tsv) files
/// into a structured [SpreadsheetDocument].
class SpreadsheetParserService {
  /// Parse spreadsheet file from an absolute file path.
  static Future<SpreadsheetDocument> parseFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    final bytes = await file.readAsBytes();
    final fileName = p.basename(filePath);
    final ext = p.extension(filePath).toLowerCase();

    final params = _SpreadsheetParseParams(
      bytes: bytes,
      filePath: filePath,
      fileName: fileName,
    );

    if (ext == '.csv' || ext == '.tsv') {
      return compute(_parseCsvIsolate, params);
    } else if (ext == '.xls') {
      return _parseLegacyXls(params);
    } else {
      return compute(_parseXlsxIsolate, params);
    }
  }

  /// Parse XLSX workbook bytes inside a background isolate.
  static SpreadsheetDocument _parseXlsxIsolate(_SpreadsheetParseParams params) {
    try {
      final excel = Excel.decodeBytes(params.bytes);
      final sheets = <SpreadsheetSheet>[];

      for (final tableKey in excel.tables.keys) {
        final table = excel.tables[tableKey];
        if (table == null) continue;

        final rows = <List<SpreadsheetCell>>[];
        final maxCols = math.max(table.maxColumns, 1);
        final colWidths = List<double>.filled(maxCols, 90.0);

        for (int r = 0; r < table.rows.length; r++) {
          final rowData = table.rows[r];
          final cellRow = <SpreadsheetCell>[];

          for (int c = 0; c < maxCols; c++) {
            Data? data;
            if (c < rowData.length) {
              data = rowData[c];
            }

            if (data == null || data.value == null) {
              cellRow.add(SpreadsheetCell.empty(rowIndex: r, columnIndex: c));
              continue;
            }

            final cell = _mapExcelDataToCell(data, r, c);
            cellRow.add(cell);

            // Auto-calculate column width based on content length
            final contentLen = cell.value.length;
            final neededWidth = math.min(math.max(contentLen * 9.5 + 24.0, 90.0), 280.0);
            if (neededWidth > colWidths[c]) {
              colWidths[c] = neededWidth;
            }
          }

          rows.add(cellRow);
        }

        sheets.add(
          SpreadsheetSheet(
            name: tableKey,
            rowCount: rows.length,
            columnCount: maxCols,
            rows: rows,
            columnWidths: colWidths,
          ),
        );
      }

      return SpreadsheetDocument(
        name: params.fileName,
        filePath: params.filePath,
        sheets: sheets.isNotEmpty
            ? sheets
            : [
                const SpreadsheetSheet(
                  name: 'Sheet1',
                  rowCount: 0,
                  columnCount: 0,
                  rows: [],
                  columnWidths: [],
                ),
              ],
      );
    } on Object catch (e, st) {
      LoggerService.error('Error parsing XLSX in isolate: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  static SpreadsheetCell _mapExcelDataToCell(Data data, int r, int c) {
    final cellValue = data.value;
    String displayValue = '';
    dynamic rawValue;
    SpreadsheetCellType type = SpreadsheetCellType.text;
    String? formula;

    if (cellValue is IntCellValue) {
      displayValue = cellValue.value.toString();
      rawValue = cellValue.value;
      type = SpreadsheetCellType.number;
    } else if (cellValue is DoubleCellValue) {
      displayValue = cellValue.value.toString();
      rawValue = cellValue.value;
      type = SpreadsheetCellType.number;
    } else if (cellValue is TextCellValue) {
      try {
        displayValue = cellValue.value.text ?? cellValue.value.toString();
      } catch (_) {
        displayValue = cellValue.value.toString();
      }
      rawValue = displayValue;
      type = SpreadsheetCellType.text;
    } else if (cellValue is BoolCellValue) {
      displayValue = cellValue.value ? 'TRUE' : 'FALSE';
      rawValue = cellValue.value;
      type = SpreadsheetCellType.boolean;
    } else if (cellValue is DateCellValue) {
      final date = DateTime(cellValue.year, cellValue.month, cellValue.day);
      displayValue = DateFormat('yyyy-MM-dd').format(date);
      rawValue = date;
      type = SpreadsheetCellType.date;
    } else if (cellValue is DateTimeCellValue) {
      final dt = DateTime(
        cellValue.year,
        cellValue.month,
        cellValue.day,
        cellValue.hour,
        cellValue.minute,
        cellValue.second,
      );
      displayValue = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      rawValue = dt;
      type = SpreadsheetCellType.date;
    } else if (cellValue is FormulaCellValue) {
      formula = cellValue.formula;
      displayValue = cellValue.formula;
      type = SpreadsheetCellType.formula;
    } else if (cellValue != null) {
      displayValue = cellValue.toString();
      rawValue = displayValue;
    }

    final style = data.cellStyle;
    bool isBold = false;
    bool isItalic = false;

    if (style != null) {
      isBold = style.isBold;
      isItalic = style.isItalic;
    }

    return SpreadsheetCell(
      rowIndex: r,
      columnIndex: c,
      value: displayValue,
      rawValue: rawValue,
      formula: formula,
      type: type,
      isBold: isBold,
      isItalic: isItalic,
    );
  }

  /// Parse CSV or TSV delimited text in background isolate with auto-delimiter detection.
  static SpreadsheetDocument _parseCsvIsolate(_SpreadsheetParseParams params) {
    String content;
    try {
      content = utf8.decode(params.bytes);
    } on Object catch (_) {
      content = latin1.decode(params.bytes);
    }

    final delimiter = _detectDelimiter(content);
    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: true,
    );

    // Normalize Windows CRLF line endings
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rawRows = converter.convert(normalized);

    int maxCols = 0;
    for (final row in rawRows) {
      if (row.length > maxCols) maxCols = row.length;
    }
    maxCols = math.max(maxCols, 1);

    final colWidths = List<double>.filled(maxCols, 90.0);
    final rows = <List<SpreadsheetCell>>[];

    for (int r = 0; r < rawRows.length; r++) {
      final rawRow = rawRows[r];
      final cellRow = <SpreadsheetCell>[];

      for (int c = 0; c < maxCols; c++) {
        if (c < rawRow.length) {
          final cellItem = rawRow[c];
          final str = cellItem?.toString() ?? '';
          SpreadsheetCellType type = SpreadsheetCellType.text;
          dynamic rawVal = cellItem;

          if (cellItem is num) {
            type = SpreadsheetCellType.number;
          } else if (cellItem is bool) {
            type = SpreadsheetCellType.boolean;
          } else if (str.toLowerCase() == 'true' || str.toLowerCase() == 'false') {
            type = SpreadsheetCellType.boolean;
            rawVal = str.toLowerCase() == 'true';
          }

          cellRow.add(
            SpreadsheetCell(
              rowIndex: r,
              columnIndex: c,
              value: str,
              rawValue: rawVal,
              type: type,
            ),
          );

          final neededWidth = math.min(math.max(str.length * 9.5 + 24.0, 90.0), 280.0);
          if (neededWidth > colWidths[c]) {
            colWidths[c] = neededWidth;
          }
        } else {
          cellRow.add(SpreadsheetCell.empty(rowIndex: r, columnIndex: c));
        }
      }

      rows.add(cellRow);
    }

    final sheet = SpreadsheetSheet(
      name: params.fileName.replaceAll(RegExp(r'\.(csv|tsv)$', caseSensitive: false), ''),
      rowCount: rows.length,
      columnCount: maxCols,
      rows: rows,
      columnWidths: colWidths,
    );

    return SpreadsheetDocument(
      name: params.fileName,
      filePath: params.filePath,
      sheets: [sheet],
      isCsv: true,
    );
  }

  /// Automatically detect delimiter from first few lines of text.
  static String _detectDelimiter(String text) {
    final sampleLines = text.split('\n').take(5).join('\n');
    final commaCount = ','.allMatches(sampleLines).length;
    final tabCount = '\t'.allMatches(sampleLines).length;
    final semiCount = ';'.allMatches(sampleLines).length;
    final pipeCount = '|'.allMatches(sampleLines).length;

    if (tabCount > commaCount && tabCount > semiCount && tabCount > pipeCount) {
      return '\t';
    }
    if (semiCount > commaCount && semiCount > tabCount && semiCount > pipeCount) {
      return ';';
    }
    if (pipeCount > commaCount && pipeCount > tabCount && pipeCount > semiCount) {
      return '|';
    }
    return ',';
  }

  /// Fallback parser for legacy binary Excel 97-2003 (.xls).
  static SpreadsheetDocument _parseLegacyXls(_SpreadsheetParseParams params) {
    LoggerService.info('Parsing legacy .xls file');
    final textBuffer = StringBuffer();

    var currentRun = <int>[];
    for (int i = 0; i < params.bytes.length; i++) {
      final b = params.bytes[i];
      if ((b >= 32 && b <= 126) || b == 9 || b == 10 || b == 13) {
        currentRun.add(b);
      } else {
        if (currentRun.length >= 3) {
          final str = String.fromCharCodes(currentRun).trim();
          if (str.length >= 3 && !str.startsWith('Workbook') && !str.startsWith('Microsoft')) {
            textBuffer.writeln(str);
          }
        }
        currentRun = [];
      }
    }

    final lines = textBuffer.toString().split('\n').where((l) => l.trim().isNotEmpty).toList();
    final rows = <List<SpreadsheetCell>>[];

    for (int r = 0; r < lines.length; r++) {
      final line = lines[r];
      rows.add([
        SpreadsheetCell(
          rowIndex: r,
          columnIndex: 0,
          value: line,
          rawValue: line,
        ),
      ]);
    }

    final sheet = SpreadsheetSheet(
      name: 'Extracted Content',
      rowCount: rows.length,
      columnCount: 1,
      rows: rows,
      columnWidths: const [300.0],
    );

    return SpreadsheetDocument(
      name: params.fileName,
      filePath: params.filePath,
      sheets: [sheet],
    );
  }
}
