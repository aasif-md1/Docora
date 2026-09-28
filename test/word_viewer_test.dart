import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docora/core/services/docx_parser_service.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_font_scale_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_renderer_widget.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/docx_toc_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List createMockDocxBytes() {
  final archive = Archive();

  // 1. word/document.xml
  const docXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Heading1"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:color w:val="FF0000"/>
        </w:rPr>
        <w:t>Chapter One: Introduction</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:i/>
          <w:u w:val="single"/>
        </w:rPr>
        <w:t>This is an italic and underlined paragraph.</w:t>
      </w:r>
    </w:p>
    <w:tbl>
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:shd w:fill="E0E0E0"/>
          </w:tcPr>
          <w:p><w:r><w:t>Header A</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:t>Header B</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
      <w:tr>
        <w:tc>
          <w:p><w:r><w:t>Cell 1</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
          <w:p><w:r><w:t>Cell 2</w:t></w:r></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
  </w:body>
</w:document>''';

  // 2. word/_rels/document.xml.rels
  const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://docora.app" TargetMode="External"/>
</Relationships>''';

  archive.addFile(ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));
  archive.addFile(ArchiveFile('word/_rels/document.xml.rels', relsXml.length, utf8.encode(relsXml)));

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  group('DOCX OpenXML Parser Tests', () {
    test('parseFile parses mock DOCX archive into structured DocxDocument', () async {
      final bytes = createMockDocxBytes();

      // Create temporary test file
      final tempDir = Directory.systemTemp.createTempSync('docx_test_');
      final testFile = File('${tempDir.path}/test_sample.docx');
      testFile.writeAsBytesSync(bytes);

      try {
        final doc = await DocxParserService.parseFile(testFile.path);

        expect(doc.blocks.length, equals(3));
        expect(doc.headings.length, equals(1));
        expect(doc.headings.first.title, equals('Chapter One: Introduction'));
        expect(doc.headings.first.level, equals(1));

        // Block 0: Heading 1 paragraph
        final p1 = doc.blocks[0] as DocxParagraphBlock;
        expect(p1.style, equals(DocxParagraphStyle.heading1));
        expect(p1.runs.first.isBold, isTrue);
        expect(p1.runs.first.color, equals(const Color(0xFFFF0000)));

        // Block 1: Centered italic paragraph
        final p2 = doc.blocks[1] as DocxParagraphBlock;
        expect(p2.alignment, equals(DocxAlignment.center));
        expect(p2.runs.first.isItalic, isTrue);
        expect(p2.runs.first.isUnderline, isTrue);

        // Block 2: Table block
        final tbl = doc.blocks[2] as DocxTableBlock;
        expect(tbl.rows.length, equals(2));
        expect(tbl.rows[0].cells.length, equals(2));
        expect(tbl.rows[0].cells[0].plainText, equals('Header A'));
        expect(tbl.rows[0].cells[0].backgroundColor, equals(const Color(0xFFE0E0E0)));
        expect(tbl.rows[1].cells[0].plainText, equals('Cell 1'));

        // Word count
        expect(doc.wordCount, greaterThan(0));
        expect(doc.characterCount, greaterThan(0));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('parseLegacyDoc extracts printable ASCII text from binary .doc', () {
      final rawData = <int>[
        0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, // OLE2 Header
        0x00, 0x00, 0x00, 0x00,
        ...utf8.encode('Annual Financial Summary 2026\n'),
        0x01, 0x02, 0x03, 0x00,
        ...utf8.encode('Total Net Revenue was strong throughout all quarters.'),
        0x00, 0x00, 0x00,
      ];

      final doc = DocxParserService.parseLegacyDoc(Uint8List.fromList(rawData));

      expect(doc.blocks.isNotEmpty, isTrue);
      expect(doc.headings.length, equals(1));
      expect(doc.headings.first.title, contains('Legacy Word Document'));
      expect(doc.wordCount, greaterThan(0));
    });
  });

  group('Word Viewer Widgets Tests', () {
    testWidgets('DocxTocSheet displays heading list and triggers selection', (tester) async {
      int? selectedBlock;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DocxTocSheet(
            headings: const [
              DocxHeading(id: 'h1', title: 'Executive Summary', level: 1, blockIndex: 0),
              DocxHeading(id: 'h2', title: 'Market Analysis', level: 2, blockIndex: 4),
            ],
            onHeadingSelected: (idx) => selectedBlock = idx,
          ),
        ),
      ));

      expect(find.text('Executive Summary'), findsOneWidget);
      expect(find.text('Market Analysis'), findsOneWidget);

      await tester.tap(find.text('Market Analysis'));
      expect(selectedBlock, equals(4));
    });

    testWidgets('DocxInfoSheet renders file metadata and word count', (tester) async {
      final doc = DocxDocument(
        blocks: const [],
        headings: const [
          DocxHeading(id: 'h1', title: 'Title', level: 1, blockIndex: 0),
        ],
        images: const {},
        wordCount: 1420,
        characterCount: 8900,
        estimatedReadingMinutes: 8,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DocxInfoSheet(
            filePath: '/storage/sample_report.docx',
            document: doc,
          ),
        ),
      ));

      expect(find.text('sample_report.docx'), findsWidgets);
      expect(find.text('1420 words (8900 characters)'), findsOneWidget);
      expect(find.text('8 min read'), findsOneWidget);
      expect(find.text('1 sections'), findsOneWidget);
    });

    testWidgets('DocxFontScaleSheet changes font scale dynamically', (tester) async {
      double? updatedScale;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DocxFontScaleSheet(
            currentScale: 1.0,
            onScaleChanged: (s) => updatedScale = s,
          ),
        ),
      ));

      expect(find.text('100%'), findsWidgets);
      expect(find.text('150%'), findsOneWidget);

      await tester.tap(find.text('150%'));
      expect(updatedScale, equals(1.5));
    });

    testWidgets('DocxSearchBarWidget handles search input and match navigation', (tester) async {
      String? searchQuery;
      bool nextTapped = false;
      bool prevTapped = false;
      bool closed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DocxSearchBarWidget(
            totalMatches: 5,
            currentMatchIndex: 1,
            onSearchChanged: (q) => searchQuery = q,
            onNextMatch: () => nextTapped = true,
            onPrevMatch: () => prevTapped = true,
            onClose: () => closed = true,
          ),
        ),
      ));

      expect(find.text('2 of 5'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'revenue');
      expect(searchQuery, equals('revenue'));

      await tester.tap(find.byTooltip('Next match'));
      expect(nextTapped, isTrue);

      await tester.tap(find.byTooltip('Previous match'));
      expect(prevTapped, isTrue);

      await tester.tap(find.byTooltip('Close search'));
      expect(closed, isTrue);
    });

    testWidgets('DocxRendererWidget renders rich selectable text with heading styles', (tester) async {
      final doc = DocxDocument(
        blocks: const [
          DocxParagraphBlock(
            runs: [DocxRun(text: 'Section 1: Overview', isBold: true)],
            style: DocxParagraphStyle.heading1,
          ),
          DocxParagraphBlock(
            runs: [DocxRun(text: 'This is the main body paragraph.')],
          ),
        ],
        headings: const [
          DocxHeading(id: 'h1', title: 'Section 1: Overview', level: 1, blockIndex: 0),
        ],
        images: const {},
        wordCount: 9,
        characterCount: 52,
        estimatedReadingMinutes: 1,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DocxRendererWidget(
            document: doc,
            fontScale: 1.0,
            readingMode: PdfReadingMode.normal,
            searchQuery: '',
            activeMatchIndex: 0,
            blockKeys: [GlobalKey(), GlobalKey()],
          ),
        ),
      ));

      expect(find.text('Section 1: Overview'), findsOneWidget);
      expect(find.text('This is the main body paragraph.'), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
    });
  });

  group('ZERO EMOJI Verification', () {
    test('Verify no emojis exist in Word viewer and parser code', () {
      final filesToCheck = [
        ...Directory('lib/features/viewer').listSync(recursive: true).whereType<File>(),
        File('lib/core/services/docx_parser_service.dart'),
      ];

      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
        unicode: true,
      );

      for (final file in filesToCheck) {
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
