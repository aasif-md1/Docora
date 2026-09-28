import 'dart:io';

import 'package:docora/data/datasources/local/app_database.dart';
import 'package:docora/data/repositories/document_repository_impl.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/presentation/widgets/page_jump_dialog.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_bottom_scrubber.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_password_dialog.dart';
import 'package:docora/features/viewer/presentation/widgets/pdf_reading_mode_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PDF Reading Mode & Tokens', () {
    test('PdfReadingMode matrix validation', () {
      expect(PdfReadingMode.normal.colorMatrix, isNull);
      expect(PdfReadingMode.normal.colorFilter, isNull);

      final darkMatrix = PdfReadingMode.dark.colorMatrix;
      expect(darkMatrix, isNotNull);
      expect(darkMatrix!.length, equals(20));

      final sepiaMatrix = PdfReadingMode.sepia.colorMatrix;
      expect(sepiaMatrix, isNotNull);
      expect(sepiaMatrix!.length, equals(20));

      final grayscaleMatrix = PdfReadingMode.grayscale.colorMatrix;
      expect(grayscaleMatrix, isNotNull);
      expect(grayscaleMatrix!.length, equals(20));

      expect(PdfReadingMode.dark.colorFilter, isNotNull);
      expect(PdfReadingMode.sepia.colorFilter, isNotNull);
      expect(PdfReadingMode.grayscale.colorFilter, isNotNull);
    });

    test('PdfLayoutMode enum labels are defined', () {
      expect(PdfLayoutMode.verticalContinuous.label, isNotEmpty);
      expect(PdfLayoutMode.verticalContinuous.description, isNotEmpty);
      expect(PdfLayoutMode.horizontalSingle.label, isNotEmpty);
      expect(PdfLayoutMode.horizontalSingle.description, isNotEmpty);
    });
  });

  group('PDF Reading Progress Database Tests', () {
    late AppDatabase db;
    late DocumentRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DocumentRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saveReadingProgress and getLastReadPage saves and restores last read position', () async {
      const path = '/storage/emulated/0/Documents/book.pdf';

      // 1. Initial state has no progress
      final initialPage = await repo.getLastReadPage(path);
      expect(initialPage, isNull);

      // 2. Save reading progress at page 42 of 250
      await repo.saveReadingProgress(
        path: path,
        pageIndex: 42,
        totalPages: 250,
      );

      // 3. Verify restored page
      final restoredPage = await repo.getLastReadPage(path);
      expect(restoredPage, equals(42));

      // 4. Update progress to page 105
      await repo.saveReadingProgress(
        path: path,
        pageIndex: 105,
        totalPages: 250,
      );

      final updatedPage = await repo.getLastReadPage(path);
      expect(updatedPage, equals(105));
    });

    test('updateDocumentPageCount updates document page count in index', () async {
      const path = '/storage/emulated/0/Documents/sample.pdf';
      final now = DateTime.now();

      await repo.upsertDocument(DocumentEntity(
        id: 1,
        path: path,
        name: 'sample.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048,
        lastModified: now,
        openCount: 0,
        isFavorite: false,
        isDeleted: false,
        tags: const [],
        category: 'pdf',
      ));

      // Page count starts null
      var doc = await repo.getDocumentByPath(path);
      expect(doc?.pageCount, isNull);

      // Update page count
      await repo.updateDocumentPageCount(path: path, pageCount: 88);

      doc = await repo.getDocumentByPath(path);
      expect(doc?.pageCount, equals(88));
    });
  });

  group('PDF Viewer Widgets Tests', () {
    testWidgets('PageJumpDialog displays and submits valid page', (tester) async {
      int? selectedPage;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedPage = await PageJumpDialog.show(
                  context,
                  currentPage: 5,
                  totalPages: 50,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Jump to Page'), findsOneWidget);
      expect(find.text('Enter a page number between 1 and 50'), findsOneWidget);

      // Clear text field and enter 25
      final textField = find.byType(TextField);
      await tester.enterText(textField, '25');
      await tester.pump();

      // Tap Go button
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(selectedPage, equals(25));
    });

    testWidgets('PdfBottomScrubber renders page indicator, slider and zoom buttons', (tester) async {
      int? scrubbedPage;
      bool jumped = false;
      bool zoomedIn = false;
      bool zoomedOut = false;
      bool resetZoom = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PdfBottomScrubber(
            currentPage: 10,
            totalPages: 100,
            currentZoom: 1.25,
            onPageScrub: (p) => scrubbedPage = p,
            onJumpTap: () => jumped = true,
            onZoomIn: () => zoomedIn = true,
            onZoomOut: () => zoomedOut = true,
            onResetZoom: () => resetZoom = true,
          ),
        ),
      ));

      expect(find.text('10 / 100'), findsOneWidget);
      expect(find.text('125%'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Drag slider
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      expect(scrubbedPage, isNotNull);

      // Tap jump
      await tester.tap(find.text('10 / 100'));
      expect(jumped, isTrue);

      // Tap zoom in
      await tester.tap(find.byTooltip('Zoom in'));
      expect(zoomedIn, isTrue);

      // Tap zoom out
      await tester.tap(find.byTooltip('Zoom out'));
      expect(zoomedOut, isTrue);

      // Tap reset
      await tester.tap(find.byTooltip('Fit to width / Reset'));
      expect(resetZoom, isTrue);
    });

    testWidgets('PdfPasswordDialog displays password input and cancel/unlock buttons', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PdfPasswordDialog(),
        ),
      ));

      expect(find.text('Password Required'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('PdfReadingModeSheet displays all visual modes', (tester) async {
      PdfReadingMode? selected;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PdfReadingModeSheet(
            currentMode: PdfReadingMode.normal,
            onModeSelected: (mode) => selected = mode,
          ),
        ),
      ));

      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Night Mode'), findsOneWidget);
      expect(find.text('Sepia'), findsOneWidget);
      expect(find.text('Grayscale'), findsOneWidget);

      await tester.tap(find.text('Sepia'));
      expect(selected, equals(PdfReadingMode.sepia));
    });
  });

  group('ZERO EMOJI Verification', () {
    test('Verify no emojis exist in viewer code and files', () {
      final dir = Directory('lib/features/viewer');
      expect(dir.existsSync(), isTrue);

      // Regex detecting Unicode emoji ranges
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
        unicode: true,
      );

      final files = dir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        final matches = emojiRegex.allMatches(content);
        expect(
          matches.isEmpty,
          isTrue,
          reason: 'File ${file.path} contains emojis: ${matches.map((m) => m.group(0)).toList()}',
        );
      }
    });
  });
}
