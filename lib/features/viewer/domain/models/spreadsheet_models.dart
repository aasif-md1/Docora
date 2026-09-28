import 'package:flutter/material.dart';

/// Converts a 0-indexed column index into Excel column letters (0 -> 'A', 25 -> 'Z', 26 -> 'AA', etc.).
String columnNumberToLetters(int columnIndex) {
  String result = '';
  int temp = columnIndex + 1;
  while (temp > 0) {
    final rem = (temp - 1) % 26;
    result = String.fromCharCode(65 + rem) + result;
    temp = ((temp - rem) / 26).floor();
  }
  return result;
}

/// Converts 0-indexed row and column indices into standard Excel coordinate (e.g. row 3, col 1 -> 'B4').
String cellCoordinate(int rowIndex, int columnIndex) =>
    '${columnNumberToLetters(columnIndex)}${rowIndex + 1}';

/// Data type of a cell value.
enum SpreadsheetCellType {
  text('Text'),
  number('Number'),
  boolean('Boolean'),
  date('Date'),
  formula('Formula'),
  empty('Empty');

  const SpreadsheetCellType(this.label);
  final String label;
}

/// Represents an individual cell within a spreadsheet sheet.
class SpreadsheetCell {
  const SpreadsheetCell({
    required this.rowIndex,
    required this.columnIndex,
    required this.value,
    this.rawValue,
    this.formula,
    this.type = SpreadsheetCellType.text,
    this.isBold = false,
    this.isItalic = false,
    this.textColor,
    this.backgroundColor,
    this.textAlign = TextAlign.left,
  });

  factory SpreadsheetCell.empty({
    required int rowIndex,
    required int columnIndex,
  }) =>
      SpreadsheetCell(
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        value: '',
        type: SpreadsheetCellType.empty,
      );

  final int rowIndex;
  final int columnIndex;
  final String value;
  final dynamic rawValue;
  final String? formula;
  final SpreadsheetCellType type;
  final bool isBold;
  final bool isItalic;
  final Color? textColor;
  final Color? backgroundColor;
  final TextAlign textAlign;

  String get coordinate => cellCoordinate(rowIndex, columnIndex);
  bool get isEmpty => value.isEmpty;
  bool get isNumeric => type == SpreadsheetCellType.number;
  bool get isFormula => type == SpreadsheetCellType.formula;
}

/// Represents a single sheet (worksheet) in a workbook or CSV.
class SpreadsheetSheet {
  const SpreadsheetSheet({
    required this.name,
    required this.rowCount,
    required this.columnCount,
    required this.rows,
    required this.columnWidths,
  });

  final String name;
  final int rowCount;
  final int columnCount;
  final List<List<SpreadsheetCell>> rows;
  final List<double> columnWidths;

  SpreadsheetCell? getCell(int rowIndex, int columnIndex) {
    if (rowIndex >= 0 &&
        rowIndex < rows.length &&
        columnIndex >= 0 &&
        columnIndex < rows[rowIndex].length) {
      return rows[rowIndex][columnIndex];
    }
    return null;
  }
}

/// Summary statistics computed for numeric cell values.
class SpreadsheetStats {
  const SpreadsheetStats({
    required this.count,
    required this.sum,
    required this.average,
    required this.min,
    required this.max,
    required this.hasNumeric,
  });

  factory SpreadsheetStats.empty() => const SpreadsheetStats(
        count: 0,
        sum: 0,
        average: 0,
        min: 0,
        max: 0,
        hasNumeric: false,
      );

  final int count;
  final double sum;
  final double average;
  final double min;
  final double max;
  final bool hasNumeric;
}

/// Complete parsed in-memory workbook representation.
class SpreadsheetDocument {
  const SpreadsheetDocument({
    required this.name,
    required this.filePath,
    required this.sheets,
    this.fileSizeBytes = 0,
    this.activeSheetIndex = 0,
    this.isCsv = false,
  });

  factory SpreadsheetDocument.empty({
    String name = '',
    String filePath = '',
  }) =>
      SpreadsheetDocument(
        name: name,
        filePath: filePath,
        sheets: const [],
      );

  final String name;
  final String filePath;
  final List<SpreadsheetSheet> sheets;
  final int fileSizeBytes;
  final int activeSheetIndex;
  final bool isCsv;

  String get title => name;
  List<String> get sheetNames => sheets.map((s) => s.name).toList();

  SpreadsheetSheet? get currentSheet =>
      sheets.isNotEmpty && activeSheetIndex < sheets.length
          ? sheets[activeSheetIndex]
          : null;
}
