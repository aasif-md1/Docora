import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docora/core/services/epub_parser_service.dart';
import 'package:docora/core/services/text_file_service.dart';
import 'package:docora/features/viewer/domain/models/epub_models.dart';
import 'package:docora/features/viewer/domain/models/pdf_viewer_state.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:docora/features/viewer/presentation/widgets/code_highlight_view.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_font_size_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/epub_toc_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/text_font_size_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/text_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/text_stats_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageDetector & Text Models Tests', () {
    test('LanguageDetector identifies code, markdown, and text formats', () {
      final dartLang = LanguageDetector.detect('main.dart');
      expect(dartLang.highlightLang, 'dart');
      expect(dartLang.isCode, true);
      expect(dartLang.isMarkdown, false);

      final mdLang = LanguageDetector.detect('README.md');
      expect(mdLang.highlightLang, 'markdown');
      expect(mdLang.isMarkdown, true);
      expect(mdLang.isCode, false);

      final txtLang = LanguageDetector.detect('notes.txt');
      expect(txtLang.highlightLang, 'plaintext');
      expect(txtLang.isCode, false);
      expect(txtLang.isMarkdown, false);

      final pyLang = LanguageDetector.detect('script.py');
      expect(pyLang.highlightLang, 'python');
      expect(pyLang.isCode, true);

      final jsonLang = LanguageDetector.detect('config.json');
      expect(jsonLang.highlightLang, 'json');
      expect(jsonLang.isCode, true);

      expect(LanguageDetector.isSupported('lib/app.dart'), true);
      expect(LanguageDetector.isSupported('notes.txt'), true);
      expect(LanguageDetector.isSupported('doc.md'), true);
      expect(LanguageDetector.isSupported('binary.exe'), false);
      expect(LanguageDetector.isSupported('unknown.xyz'), false);
    });

    test('TextDocument calculates lines, words, and characters correctly', () {
      const content = 'Hello Docora world!\nThis is line two.\nFinal third line.';
      final lines = content.split('\n');
      final doc = TextDocument(
        filePath: '/mock/test.txt',
        fileName: 'test.txt',
        content: content,
        fileSizeBytes: content.length,
        encodingName: 'UTF-8',
        highlightLanguage: 'plaintext',
        languageLabel: 'Plain Text',
        isCode: false,
        isMarkdown: false,
        lines: lines,
      );

      expect(doc.lineCount, 3);
      expect(doc.wordCount, 10);
      expect(doc.characterCount, content.length);
    });
  });

  group('TextFileService Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('docora_text_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Reads standard UTF-8 text file', () async {
      final file = File('${tempDir.path}/sample.txt');
      file.writeAsStringSync('First line\nSecond line\nThird line');

      final doc = await TextFileService.readFile(file.path);
      expect(doc.fileName, 'sample.txt');
      expect(doc.lineCount, 3);
      expect(doc.encodingName, 'UTF-8');
      expect(doc.content, contains('Second line'));
    });

    test('Detects and strips UTF-8 BOM', () async {
      final file = File('${tempDir.path}/bom.txt');
      final bomBytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('BOM Text Line')];
      file.writeAsBytesSync(bomBytes);

      final doc = await TextFileService.readFile(file.path);
      expect(doc.encodingName, 'UTF-8 (BOM)');
      expect(doc.content, 'BOM Text Line');
    });

    test('Detects and decodes UTF-16 LE with BOM', () async {
      final file = File('${tempDir.path}/utf16le.txt');
      const text = 'Hello UTF-16';
      final units = text.codeUnits;
      final bytes = <int>[0xFF, 0xFE];
      for (final u in units) {
        bytes.add(u & 0xFF);
        bytes.add((u >> 8) & 0xFF);
      }
      file.writeAsBytesSync(bytes);

      final doc = await TextFileService.readFile(file.path);
      expect(doc.encodingName, 'UTF-16 LE');
      expect(doc.content, 'Hello UTF-16');
    });

    test('Detects and decodes UTF-16 BE with BOM', () async {
      final file = File('${tempDir.path}/utf16be.txt');
      const text = 'Hello BE';
      final units = text.codeUnits;
      final bytes = <int>[0xFE, 0xFF];
      for (final u in units) {
        bytes.add((u >> 8) & 0xFF);
        bytes.add(u & 0xFF);
      }
      file.writeAsBytesSync(bytes);

      final doc = await TextFileService.readFile(file.path);
      expect(doc.encodingName, 'UTF-16 BE');
      expect(doc.content, 'Hello BE');
    });

    test('Throws FileSystemException on non-existent file', () async {
      expect(
        () => TextFileService.readFile('${tempDir.path}/non_existent.txt'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('EPUB Models & Parser Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('docora_epub_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('EpubChapter plainText extracts clean text without markup', () {
      const chapter = EpubChapter(
        id: 'c1',
        title: 'Introduction',
        href: 'intro.xhtml',
        htmlContent: '<html><body><h1>Intro</h1><p>Welcome to <b>Docora</b> e-reader!</p></body></html>',
        chapterIndex: 0,
      );

      expect(chapter.plainText, contains('Welcome to Docora e-reader!'));
      expect(chapter.plainText, isNot(contains('<p>')));
    });

    test('Parses synthetic EPUB package correctly', () async {
      final archive = Archive();

      const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

      const opfXml = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>The Analytical Engine</dc:title>
    <dc:creator>Ada Lovelace</dc:creator>
    <dc:publisher>Docora Editions</dc:publisher>
    <dc:description>Foundations of automated computing.</dc:description>
  </metadata>
  <manifest>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''';
      archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)));

      const ch1Html = '''<html><head><title>Chapter 1: The Design</title></head>
<body><p>Analytical engines compute mechanical operations automatically.</p></body></html>''';
      archive.addFile(ArchiveFile('OEBPS/ch1.xhtml', ch1Html.length, utf8.encode(ch1Html)));

      const ch2Html = '''<html><body><h1>Chapter 2: Algorithms</h1>
<p>Sequence of instructions for calculations.</p></body></html>''';
      archive.addFile(ArchiveFile('OEBPS/ch2.xhtml', ch2Html.length, utf8.encode(ch2Html)));

      const ncxXml = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Chapter 1: The Design</text></navLabel>
      <content src="ch1.xhtml"/>
    </navPoint>
    <navPoint id="np2" playOrder="2">
      <navLabel><text>Chapter 2: Algorithms</text></navLabel>
      <content src="ch2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';
      archive.addFile(ArchiveFile('OEBPS/toc.ncx', ncxXml.length, utf8.encode(ncxXml)));

      final zipBytes = ZipEncoder().encode(archive)!;
      final epubFile = File('${tempDir.path}/test_book.epub');
      epubFile.writeAsBytesSync(zipBytes);

      final doc = await EpubParserService.parseFile(epubFile.path);

      expect(doc.title, 'The Analytical Engine');
      expect(doc.author, 'Ada Lovelace');
      expect(doc.publisher, 'Docora Editions');
      expect(doc.description, 'Foundations of automated computing.');
      expect(doc.chapterCount, 2);

      final firstCh = doc.getChapter(0);
      expect(firstCh, isNotNull);
      expect(firstCh!.title, 'Chapter 1: The Design');
      expect(firstCh.plainText, contains('Analytical engines compute mechanical operations'));

      final secondCh = doc.getChapter(1);
      expect(secondCh, isNotNull);
      expect(secondCh!.title, 'Chapter 2: Algorithms');
      expect(secondCh.plainText, contains('Sequence of instructions for calculations'));

      expect(doc.toc.length, 2);
      expect(doc.toc[0].title, 'Chapter 1: The Design');
      expect(doc.toc[0].targetChapterIndex, 0);
      expect(doc.toc[1].title, 'Chapter 2: Algorithms');
      expect(doc.toc[1].targetChapterIndex, 1);
    });

    test('Gracefully parses fallback when container.xml is absent', () async {
      final archive = Archive();
      const ch1Html = '<html><body><h1>Standalone Section</h1><p>Content without OPF</p></body></html>';
      archive.addFile(ArchiveFile('page1.html', ch1Html.length, utf8.encode(ch1Html)));

      final zipBytes = ZipEncoder().encode(archive)!;
      final epubFile = File('${tempDir.path}/orphan.epub');
      epubFile.writeAsBytesSync(zipBytes);

      final doc = await EpubParserService.parseFile(epubFile.path);
      expect(doc.chapterCount, 1);
      expect(doc.chapters.first.title, 'Standalone Section');
    });
  });

  group('Text & EPUB UI Widgets Tests', () {
    testWidgets('CodeHighlightView renders text and gutter line numbers', (tester) async {
      const doc = TextDocument(
        filePath: '/mock/code.dart',
        fileName: 'code.dart',
        content: 'void main() {\n  print("Docora");\n}',
        fileSizeBytes: 32,
        encodingName: 'UTF-8',
        highlightLanguage: 'dart',
        languageLabel: 'Dart',
        isCode: true,
        isMarkdown: false,
        lines: ['void main() {', '  print("Docora");', '}'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeHighlightView(
              document: doc,
              fontSize: 14.0,
              showLineNumbers: true,
              wrapLines: true,
            ),
          ),
        ),
      );

      expect(find.text('void main() {'), findsOneWidget);
      expect(find.text('  print("Docora");'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('TextSearchBar displays match index and search controls', (tester) async {
      String updatedQuery = '';
      bool prevCalled = false;
      bool nextCalled = false;
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextSearchBar(
              totalMatches: 5,
              currentMatchIndex: 1,
              onQueryChanged: (q) => updatedQuery = q,
              onPreviousMatch: () => prevCalled = true,
              onNextMatch: () => nextCalled = true,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      // Match counter only shows when text field is not empty
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();
      expect(updatedQuery, 'test query');

      expect(find.text('2 of 5'), findsOneWidget);

      await tester.tap(find.byTooltip('Next match'));
      expect(nextCalled, true);

      await tester.tap(find.byTooltip('Previous match'));
      expect(prevCalled, true);

      await tester.tap(find.byTooltip('Close search'));
      expect(closeCalled, true);
    });

    testWidgets('TextStatsSheet displays lines, words, chars, size, and encoding', (tester) async {
      const doc = TextDocument(
        filePath: '/mock/doc.txt',
        fileName: 'doc.txt',
        content: 'Line 1\nLine 2',
        fileSizeBytes: 2048,
        encodingName: 'UTF-8',
        highlightLanguage: 'plaintext',
        languageLabel: 'Plain Text',
        isCode: false,
        isMarkdown: false,
        lines: ['Line 1', 'Line 2'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextStatsSheet(document: doc),
          ),
        ),
      );

      expect(find.text('File Details & Statistics'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 lines
      expect(find.text('4'), findsOneWidget); // 4 words
      expect(find.text('UTF-8'), findsOneWidget);
      expect(find.text('Plain Text'), findsOneWidget);
    });

    testWidgets('TextFontSizeSheet controls font size and view toggles', (tester) async {
      double selectedSize = 14.0;
      bool lineNumbers = true;
      bool wrap = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFontSizeSheet(
              currentFontSize: selectedSize,
              onFontSizeChanged: (s) => selectedSize = s,
              showLineNumbers: lineNumbers,
              onToggleLineNumbers: () => lineNumbers = !lineNumbers,
              wrapLines: wrap,
              onToggleWrapLines: () => wrap = !wrap,
            ),
          ),
        ),
      );

      expect(find.text('View & Typography Settings'), findsOneWidget);
      expect(find.text('14 pt'), findsOneWidget);

      await tester.tap(find.text('18 pt'));
      await tester.pump();
      expect(selectedSize, 18.0);
    });

    testWidgets('EpubTocSheet lists chapters and triggers selection', (tester) async {
      int selectedIdx = -1;
      const toc = [
        EpubTocEntry(title: 'Chapter I: Genesis', href: 'ch1.xhtml'),
        EpubTocEntry(title: 'Chapter II: Exodus', href: 'ch2.xhtml', targetChapterIndex: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubTocSheet(
              tocEntries: toc,
              currentChapterIndex: 0,
              onChapterSelected: (idx) => selectedIdx = idx,
            ),
          ),
        ),
      );

      expect(find.text('Table of Contents'), findsOneWidget);
      expect(find.text('Chapter I: Genesis'), findsOneWidget);
      expect(find.text('Chapter II: Exodus'), findsOneWidget);

      await tester.tap(find.text('Chapter II: Exodus'));
      expect(selectedIdx, 1);
    });

    testWidgets('EpubInfoSheet displays publication metadata and chips', (tester) async {
      const doc = EpubDocument(
        title: 'Principles of Science',
        filePath: '/mock/book.epub',
        fileSizeBytes: 1048576,
        chapters: [],
        toc: [],
        author: 'Charles Babbage',
        publisher: 'Cambridge Press',
        description: 'A treatise on scientific instruments.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpubInfoSheet(document: doc),
          ),
        ),
      );

      expect(find.text('Publication Details'), findsOneWidget);
      expect(find.text('Principles of Science'), findsOneWidget);
      expect(find.text('Charles Babbage'), findsOneWidget);
      expect(find.text('Cambridge Press'), findsOneWidget);
      expect(find.text('A treatise on scientific instruments.'), findsOneWidget);
      expect(find.text('EPUB E-Book'), findsOneWidget);
    });

    testWidgets('EpubFontSizeSheet allows selecting comfort themes and font sizes', (tester) async {
      double currentSize = 16.0;
      PdfReadingMode currentMode = PdfReadingMode.normal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubFontSizeSheet(
              currentFontSize: currentSize,
              onFontSizeChanged: (s) => currentSize = s,
              currentReadingMode: currentMode,
              onReadingModeChanged: (m) => currentMode = m,
            ),
          ),
        ),
      );

      expect(find.text('Reading Display Settings'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Sepia'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      await tester.tap(find.text('Sepia'));
      expect(currentMode, PdfReadingMode.sepia);

      await tester.tap(find.text('20'));
      expect(currentSize, 20.0);
    });
  });

  group('Phase 8 Zero-Emoji Policy Tests', () {
    test('Ensures ZERO emojis exist in all Phase 8 source files', () {
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
        unicode: true,
      );

      final phase8Files = [
        'lib/features/viewer/domain/models/text_document_models.dart',
        'lib/core/services/text_file_service.dart',
        'lib/features/viewer/presentation/providers/text_viewer_providers.dart',
        'lib/features/viewer/presentation/widgets/text_search_bar.dart',
        'lib/features/viewer/presentation/widgets/text_stats_sheet.dart',
        'lib/features/viewer/presentation/widgets/text_font_size_sheet.dart',
        'lib/features/viewer/presentation/widgets/code_highlight_view.dart',
        'lib/features/viewer/presentation/text_viewer_screen.dart',
        'lib/features/viewer/domain/models/epub_models.dart',
        'lib/core/services/epub_parser_service.dart',
        'lib/features/viewer/presentation/providers/epub_providers.dart',
        'lib/features/viewer/presentation/widgets/epub_toc_sheet.dart',
        'lib/features/viewer/presentation/widgets/epub_info_sheet.dart',
        'lib/features/viewer/presentation/widgets/epub_chapter_view.dart',
        'lib/features/viewer/presentation/widgets/epub_font_size_sheet.dart',
        'lib/features/viewer/presentation/epub_viewer_screen.dart',
      ];

      for (final relPath in phase8Files) {
        final file = File(relPath);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final matches = emojiRegex.allMatches(content);
          expect(
            matches.isEmpty,
            true,
            reason: 'File $relPath violates ZERO-EMOJI constraint with match: ${matches.map((m) => m.group(0))}',
          );
        }
      }
    });
  });
}
