import 'dart:io';

import 'package:docora/core/services/spreadsheet_parser_service.dart';
import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_formula_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_sheet_tabs.dart';
import 'package:docora/features/viewer/presentation/widgets/spreadsheet_stats_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Spreadsheet Coordinate & Letter Helpers', () {
    test('columnNumberToLetters handles single and double letters', () {
      expect(columnNumberToLetters(0), 'A');
      expect(columnNumberToLetters(1), 'B');
      expect(columnNumberToLetters(25), 'Z');
      expect(columnNumberToLetters(26), 'AA');
      expect(columnNumberToLetters(27), 'AB');
      expect(columnNumberToLetters(51), 'AZ');
      expect(columnNumberToLetters(52), 'BA');
    });

    test('cellCoordinate formats row and column numbers correctly', () {
      expect(cellCoordinate(0, 0), 'A1');
      expect(cellCoordinate(4, 1), 'B5');
      expect(cellCoordinate(99, 25), 'Z100');
      expect(cellCoordinate(10, 26), 'AA11');
    });
  });

  group('Spreadsheet Models', () {
    test('SpreadsheetCell identifies data types correctly', () {
      const numCell = SpreadsheetCell(
        rowIndex: 0,
        columnIndex: 0,
        value: '123.45',
        rawValue: 123.45,
        type: SpreadsheetCellType.number,
      );
      expect(numCell.isNumeric, isTrue);
      expect(numCell.isFormula, isFalse);
      expect(numCell.isEmpty, isFalse);
      expect(numCell.coordinate, 'A1');

      const formulaCell = SpreadsheetCell(
        rowIndex: 1,
        columnIndex: 2,
        value: '300',
        rawValue: 300,
        type: SpreadsheetCellType.formula,
        formula: '=SUM(A1:A5)',
      );
      expect(formulaCell.isFormula, isTrue);
      expect(formulaCell.formula, '=SUM(A1:A5)');
      expect(formulaCell.coordinate, 'C2');

      final emptyCell = SpreadsheetCell.empty(rowIndex: 3, columnIndex: 3);
      expect(emptyCell.isEmpty, isTrue);
    });

    test('SpreadsheetSheet accessors and bounds', () {
      const rows = [
        [
          SpreadsheetCell(
            rowIndex: 0,
            columnIndex: 0,
            value: 'ID',
            rawValue: 'ID',
          ),
          SpreadsheetCell(
            rowIndex: 0,
            columnIndex: 1,
            value: 'Amount',
            rawValue: 'Amount',
          ),
        ],
        [
          SpreadsheetCell(
            rowIndex: 1,
            columnIndex: 0,
            value: '1',
            rawValue: 1,
            type: SpreadsheetCellType.number,
          ),
          SpreadsheetCell(
            rowIndex: 1,
            columnIndex: 1,
            value: '100.5',
            rawValue: 100.5,
            type: SpreadsheetCellType.number,
          ),
        ],
      ];

      const sheet = SpreadsheetSheet(
        name: 'Summary',
        rows: rows,
        rowCount: 2,
        columnCount: 2,
        columnWidths: [100.0, 100.0],
      );

      expect(sheet.rowCount, 2);
      expect(sheet.columnCount, 2);
      expect(sheet.getCell(0, 0)?.value, 'ID');
      expect(sheet.getCell(1, 1)?.value, '100.5');
      expect(sheet.getCell(5, 5), isNull);
    });
  });

  group('SpreadsheetParserService', () {
    test('Parses standard comma-separated CSV with numbers and text', () async {
      final tempDir = await Directory.systemTemp.createTemp('csv_test_');
      final file = File('${tempDir.path}/test.csv');
      await file.writeAsString('Name,Score,Passed\nAlice,95.5,true\nBob,82,false\n');

      final doc = await SpreadsheetParserService.parseFile(file.path);
      expect(doc.sheets.length, 1);
      final sheet = doc.sheets.first;
      expect(sheet.rowCount, 3);
      expect(sheet.columnCount, 3);
      expect(sheet.getCell(0, 0)?.value, 'Name');
      expect(sheet.getCell(1, 1)?.value, '95.5');
      expect(sheet.getCell(1, 1)?.type, SpreadsheetCellType.number);
      expect(sheet.getCell(2, 2)?.value, 'false');
      expect(sheet.getCell(2, 2)?.type, SpreadsheetCellType.boolean);

      await tempDir.delete(recursive: true);
    });

    test('Auto-detects semicolon and tab delimiters in CSV', () async {
      final tempDir = await Directory.systemTemp.createTemp('csv_tsv_');

      // Semicolon test
      final semiFile = File('${tempDir.path}/semi.csv');
      await semiFile.writeAsString('Product;Price;Qty\nApple;1.5;10\nBanana;0.75;25');
      final semiDoc = await SpreadsheetParserService.parseFile(semiFile.path);
      expect(semiDoc.sheets.first.rowCount, 3);
      expect(semiDoc.sheets.first.columnCount, 3);
      expect(semiDoc.sheets.first.getCell(1, 0)?.value, 'Apple');

      // TSV test
      final tsvFile = File('${tempDir.path}/test.tsv');
      await tsvFile.writeAsString('A\tB\tC\n1\t2\t3\n4\t5\t6');
      final tsvDoc = await SpreadsheetParserService.parseFile(tsvFile.path);
      expect(tsvDoc.sheets.first.rowCount, 3);
      expect(tsvDoc.sheets.first.columnCount, 3);
      expect(tsvDoc.sheets.first.getCell(2, 2)?.value, '6');

      await tempDir.delete(recursive: true);
    });
  });

  group('Spreadsheet UI Widgets', () {
    testWidgets('SpreadsheetFormulaBar displays active coordinate and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpreadsheetFormulaBar(
              selectedCell: SpreadsheetCell(
                rowIndex: 2,
                columnIndex: 1, // B3
                value: '450.00',
                rawValue: 450.0,
                type: SpreadsheetCellType.formula,
                formula: '=SUM(B1:B2)',
              ),
            ),
          ),
        ),
      );

      expect(find.text('B3'), findsOneWidget);
      expect(find.text('=SUM(B1:B2)'), findsOneWidget);
    });

    testWidgets('SpreadsheetStatsBar displays count, sum, avg, min, max', (tester) async {
      const stats = SpreadsheetStats(
        count: 5,
        sum: 150.0,
        average: 30.0,
        min: 10.0,
        max: 50.0,
        hasNumeric: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpreadsheetStatsBar(stats: stats),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('SpreadsheetSheetTabs displays tabs and notifies selection', (tester) async {
      int? selectedIndex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpreadsheetSheetTabs(
              sheetNames: const ['Q1 Sales', 'Q2 Sales', 'Forecast'],
              currentIndex: 0,
              onSheetSelected: (idx) => selectedIndex = idx,
            ),
          ),
        ),
      );

      expect(find.text('Q1 Sales'), findsOneWidget);
      expect(find.text('Q2 Sales'), findsOneWidget);
      expect(find.text('Forecast'), findsOneWidget);

      await tester.tap(find.text('Forecast'));
      expect(selectedIndex, 2);
    });

    testWidgets('SpreadsheetSearchBar calls onQueryChanged and navigates matches', (tester) async {
      String query = '';
      bool nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpreadsheetSearchBar(
              totalMatches: 3,
              currentMatchIndex: 1,
              onQueryChanged: (q) => query = q,
              onPreviousMatch: () {},
              onNextMatch: () => nextTapped = true,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'revenue');
      expect(query, 'revenue');

      await tester.pump();
      expect(find.text('2 of 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Next match'));
      expect(nextTapped, isTrue);
    });

    testWidgets('SpreadsheetInfoSheet renders workbook metadata without errors', (tester) async {
      final doc = SpreadsheetDocument(
        filePath: '/mock/sales_report.xlsx',
        name: 'sales_report.xlsx',
        fileSizeBytes: 204850,
        sheets: const [
          SpreadsheetSheet(
            name: '2026 Data',
            rows: [],
            rowCount: 100,
            columnCount: 15,
            columnWidths: [],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpreadsheetInfoSheet(
              document: doc,
              activeSheetIndex: 0,
            ),
          ),
        ),
      );

      expect(find.text('Workbook Information'), findsOneWidget);
      expect(find.text('sales_report.xlsx'), findsOneWidget);
      expect(find.text('2026 Data'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('Strict Zero-Emoji Rule Validation for Phase 6', () {
    test('Ensures no emoji characters exist in spreadsheet implementation files', () {
      final dir = Directory('lib/features/viewer');
      final files = dir.listSync(recursive: true).whereType<File>().where(
            (f) =>
                f.path.contains('spreadsheet') &&
                f.path.endsWith('.dart'),
          );

      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
        unicode: true,
      );

      for (final f in files) {
        final content = f.readAsStringSync();
        final matches = emojiRegex.allMatches(content);
        expect(
          matches.isEmpty,
          isTrue,
          reason: 'Found emoji in ${f.path}: ${matches.map((m) => m.group(0)).toList()}',
        );
      }
    });
  });
}
