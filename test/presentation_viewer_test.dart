import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docora/core/services/presentation_parser_service.dart';
import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:docora/features/viewer/presentation/widgets/presentation_controls_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/presentation_info_sheet.dart';
import 'package:docora/features/viewer/presentation/widgets/presentation_search_bar.dart';
import 'package:docora/features/viewer/presentation/widgets/slide_renderer_widget.dart';
import 'package:docora/features/viewer/presentation/widgets/slide_thumbnail_scrubber.dart';
import 'package:docora/features/viewer/presentation/widgets/speaker_notes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Presentation Models Tests', () {
    test('PresentationSlide derives displayTitle correctly', () {
      // 1. Explicit title
      const slide1 = PresentationSlide(
        slideIndex: 0,
        shapes: [],
        title: 'Q3 Financial Review',
      );
      expect(slide1.displayTitle, 'Q3 Financial Review');

      // 2. Title shape
      const slide2 = PresentationSlide(
        slideIndex: 1,
        shapes: [
          SlideShape(
            title: true,
            paragraphs: [
              SlideParagraph(
                runs: [SlideTextRun(text: 'Product Roadmap 2026')],
              ),
            ],
          ),
        ],
      );
      expect(slide2.displayTitle, 'Product Roadmap 2026');

      // 3. Fallback to Slide N
      const slide3 = PresentationSlide(
        slideIndex: 2,
        shapes: [],
      );
      expect(slide3.displayTitle, 'Slide 3');
    });

    test('PresentationDocument aspect ratio and notes count', () {
      const docWidescreen = PresentationDocument(
        title: 'Deck.pptx',
        filePath: '/mock/Deck.pptx',
        fileSizeBytes: 1024,
        slides: [
          PresentationSlide(
            slideIndex: 0,
            shapes: [],
            speakerNotes: 'Remember to introduce team',
          ),
          PresentationSlide(
            slideIndex: 1,
            shapes: [],
          ),
        ],
      );

      expect(docWidescreen.isWidescreen, isTrue);
      expect(docWidescreen.aspectRatio, closeTo(16 / 9, 0.05));
      expect(docWidescreen.slideCount, 2);
      expect(docWidescreen.notesCount, 1);

      const docStandard = PresentationDocument(
        title: 'OldDeck.pptx',
        filePath: '/mock/OldDeck.pptx',
        fileSizeBytes: 512,
        slideWidth: 720,
        slides: [],
      );
      expect(docStandard.isWidescreen, isFalse);
      expect(docStandard.aspectRatio, closeTo(4 / 3, 0.05));
    });
  });

  group('Presentation Parser Service Tests', () {
    test('Parses mock PPTX OpenXML archive into structured PresentationDocument', () async {
      final archive = Archive();

      // ppt/presentation.xml
      const presXml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:sldSz cx="9144000" cy="5143500"/>
  <p:sldIdLst>
    <p:sldId id="256" r:id="rId1"/>
  </p:sldIdLst>
</p:presentation>''';
      archive.addFile(ArchiveFile('ppt/presentation.xml', presXml.length, utf8.encode(presXml)));

      // ppt/_rels/presentation.xml.rels
      const presRelsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presRelsXml.length, utf8.encode(presRelsXml)));

      // ppt/slides/slide1.xml
      const slide1Xml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:sp>
        <p:nvSpPr>
          <p:nvPr>
            <p:ph type="title"/>
          </p:nvPr>
        </p:nvSpPr>
        <p:txBody>
          <a:p>
            <a:r>
              <a:t>Executive Summary</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
      <p:sp>
        <p:txBody>
          <a:p>
            <a:pPr lvl="1"/>
            <a:r>
              <a:t>Key Revenue Drivers</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';
      archive.addFile(ArchiveFile('ppt/slides/slide1.xml', slide1Xml.length, utf8.encode(slide1Xml)));

      // ppt/slides/_rels/slide1.xml.rels
      const slide1RelsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rIdNotes" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesSlide" Target="../notesSlides/notesSlide1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('ppt/slides/_rels/slide1.xml.rels', slide1RelsXml.length, utf8.encode(slide1RelsXml)));

      // ppt/notesSlides/notesSlide1.xml
      const notesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:notes xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:sp>
        <p:nvSpPr>
          <p:nvPr>
            <p:ph type="body"/>
          </p:nvPr>
        </p:nvSpPr>
        <p:txBody>
          <a:p>
            <a:r>
              <a:t>Mention the 25% growth metric</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:notes>''';
      archive.addFile(ArchiveFile('ppt/notesSlides/notesSlide1.xml', notesXml.length, utf8.encode(notesXml)));

      final zipBytes = ZipEncoder().encode(archive);
      final tempDir = await Directory.systemTemp.createTemp('pptx_test_');
      final testFile = File('${tempDir.path}/test.pptx');
      await testFile.writeAsBytes(zipBytes!);

      final doc = await PresentationParserService.parseFile(testFile.path);
      expect(doc.slideCount, 1);
      final slide = doc.slides.first;
      expect(slide.displayTitle, 'Executive Summary');
      expect(slide.shapes.length, 2);
      expect(slide.shapes[1].paragraphs.first.isBullet, isTrue);
      expect(slide.speakerNotes, contains('Mention the 25% growth metric'));

      await tempDir.delete(recursive: true);
    });

    test('Parses theme typography (+mj-lt, +mn-lt) and inherits master shapes and background', () async {
      final archive = Archive();

      // ppt/presentation.xml
      const presXml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:sldSz cx="9144000" cy="5143500"/>
  <p:sldIdLst>
    <p:sldId id="256" r:id="rId1"/>
  </p:sldIdLst>
</p:presentation>''';
      archive.addFile(ArchiveFile('ppt/presentation.xml', presXml.length, utf8.encode(presXml)));

      // ppt/_rels/presentation.xml.rels
      const presRelXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presRelXml.length, utf8.encode(presRelXml)));

      // ppt/theme/theme1.xml
      const themeXml = '''<?xml version="1.0" encoding="UTF-8"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
  <a:themeElements>
    <a:clrScheme name="Custom">
      <a:dk1><a:srgbClr val="000000"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
    </a:clrScheme>
    <a:fontScheme name="Office">
      <a:majorFont>
        <a:latin typeface="Montserrat"/>
      </a:majorFont>
      <a:minorFont>
        <a:latin typeface="Open Sans"/>
      </a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Office">
      <a:bgFillStyleLst>
        <a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>
      </a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>''';
      archive.addFile(ArchiveFile('ppt/theme/theme1.xml', themeXml.length, utf8.encode(themeXml)));

      // ppt/slides/slide1.xml
      const slideXml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:cSld>
    <p:spTree>
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="2" name="Title 1"/>
          <p:cNvSpPr/>
          <p:nvPr><p:ph type="title"/></p:nvPr>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="457200" y="274320"/><a:ext cx="8229600" cy="914400"/></a:xfrm>
        </p:spPr>
        <p:txBody>
          <p:p>
            <p:r>
              <p:rPr><a:latin typeface="+mj-lt"/></p:rPr>
              <p:t>Heading With Major Font</p:t>
            </p:r>
          </p:p>
        </p:txBody>
      </p:sp>
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="3" name="Body 2"/>
          <p:cNvSpPr/>
          <p:nvPr><p:ph type="body"/></p:nvPr>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="457200" y="1371600"/><a:ext cx="8229600" cy="3200400"/></a:xfrm>
        </p:spPr>
        <p:txBody>
          <p:p>
            <p:r>
              <p:rPr><a:latin typeface="+mn-lt"/></p:rPr>
              <p:t>Body With Minor Font</p:t>
            </p:r>
          </p:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';
      archive.addFile(ArchiveFile('ppt/slides/slide1.xml', slideXml.length, utf8.encode(slideXml)));

      // ppt/slides/_rels/slide1.xml.rels
      const slideRelXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('ppt/slides/_rels/slide1.xml.rels', slideRelXml.length, utf8.encode(slideRelXml)));

      // ppt/slideLayouts/slideLayout1.xml
      const layoutXml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:sldLayout xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:cSld>
    <p:spTree/>
  </p:cSld>
</p:sldLayout>''';
      archive.addFile(ArchiveFile('ppt/slideLayouts/slideLayout1.xml', layoutXml.length, utf8.encode(layoutXml)));

      // ppt/slideLayouts/_rels/slideLayout1.xml.rels
      const layoutRelXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile('ppt/slideLayouts/_rels/slideLayout1.xml.rels', layoutRelXml.length, utf8.encode(layoutRelXml)));

      // ppt/slideMasters/slideMaster1.xml with non-placeholder header theme banner
      const masterXml = '''<?xml version="1.0" encoding="UTF-8"?>
<p:sldMaster xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:cSld>
    <p:spTree>
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="101" name="Master Header Stripe"/>
          <p:cNvSpPr/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="0" y="0"/><a:ext cx="9144000" cy="200000"/></a:xfrm>
          <a:solidFill><a:srgbClr val="1E40AF"/></a:solidFill>
        </p:spPr>
      </p:sp>
    </p:spTree>
  </p:cSld>
</p:sldMaster>''';
      archive.addFile(ArchiveFile('ppt/slideMasters/slideMaster1.xml', masterXml.length, utf8.encode(masterXml)));

      final zipBytes = ZipEncoder().encode(archive);
      final tempDir = await Directory.systemTemp.createTemp('pptx_theme_test_');
      final testFile = File('${tempDir.path}/theme_test.pptx');
      await testFile.writeAsBytes(zipBytes!);

      final doc = await PresentationParserService.parseFile(testFile.path);
      expect(doc.slideCount, 1);
      final slide = doc.slides.first;

      // Master shape (header stripe) was inherited and placed behind slide shapes
      expect(slide.shapes.length, 3);
      final masterStripe = slide.shapes.first;
      expect(masterStripe.backgroundColor, const Color(0xFF1E40AF));

      // Heading resolved +mj-lt to Montserrat
      final titleShape = slide.shapes[1];
      expect(titleShape.paragraphs.first.runs.first.fontFamily, 'Montserrat');

      // Body resolved +mn-lt to Open Sans
      final bodyShape = slide.shapes[2];
      expect(bodyShape.paragraphs.first.runs.first.fontFamily, 'Open Sans');

      // Default background is light white, not dark
      expect(slide.backgroundColor, const Color(0xFFFFFFFF));

      await tempDir.delete(recursive: true);
    });
  });

  group('Presentation UI Widgets Tests', () {
    testWidgets('SlideRendererWidget renders slide title and bullet points', (tester) async {
      const slide = PresentationSlide(
        slideIndex: 0,
        title: 'Project Milestones',
        shapes: [
          SlideShape(
            paragraphs: [
              SlideParagraph(
                runs: [SlideTextRun(text: 'Phase 1: Foundation completed')],
                isBullet: true,
                level: 1,
              ),
              SlideParagraph(
                runs: [SlideTextRun(text: 'Phase 2: Core modules active')],
                isBullet: true,
                level: 1,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideRendererWidget(slide: slide),
          ),
        ),
      );

      expect(find.text('Project Milestones'), findsOneWidget);
      expect(find.text('Phase 1: Foundation completed'), findsOneWidget);
      expect(find.text('Phase 2: Core modules active'), findsOneWidget);
    });

    testWidgets('SlideRendererWidget renders diagram shapes, ellipses, and typography', (tester) async {
      const slide = PresentationSlide(
        slideIndex: 0,
        title: 'System Flowchart',
        shapes: [
          SlideShape(
            shapeType: 'ellipse',
            rotationDegrees: 45.0,
            backgroundColor: Color(0xFF38BDF8),
            rect: SlideRect(left: 0.1, top: 0.2, width: 0.3, height: 0.2),
            paragraphs: [
              SlideParagraph(
                runs: [
                  SlideTextRun(
                    text: 'Process Node',
                    fontFamily: 'Roboto',
                    fontSize: 18.0,
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideRendererWidget(slide: slide),
          ),
        ),
      );

      expect(find.text('System Flowchart'), findsOneWidget);
      expect(find.text('Process Node'), findsOneWidget);
    });


    testWidgets('SlideThumbnailScrubber renders slide items and handles tap', (tester) async {
      int? tappedIndex;
      const slides = [
        PresentationSlide(slideIndex: 0, title: 'Introduction', shapes: []),
        PresentationSlide(slideIndex: 1, title: 'Architecture', shapes: []),
        PresentationSlide(slideIndex: 2, title: 'Conclusion', shapes: []),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideThumbnailScrubber(
              slides: slides,
              currentSlideIndex: 0,
              onSlideSelected: (idx) => tappedIndex = idx,
            ),
          ),
        ),
      );

      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Architecture'), findsOneWidget);
      expect(find.text('Conclusion'), findsOneWidget);

      await tester.tap(find.text('Architecture'));
      expect(tappedIndex, 1);
    });

    testWidgets('SpeakerNotesSheet displays notes when present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeakerNotesSheet(
              slideIndex: 2,
              notes: 'Spend no more than 3 minutes on this slide.',
            ),
          ),
        ),
      );

      expect(find.text('Speaker Notes (Slide 3)'), findsOneWidget);
      expect(find.text('Spend no more than 3 minutes on this slide.'), findsOneWidget);
    });

    testWidgets('PresentationControlsBar triggers slide navigation and actions', (tester) async {
      bool nextTapped = false;
      bool playTapped = false;
      bool fsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresentationControlsBar(
              currentIndex: 2,
              totalSlides: 10,
              onPrevious: () {},
              onNext: () => nextTapped = true,
              isPlaying: false,
              onTogglePlay: () => playTapped = true,
              hasNotes: true,
              onToggleNotes: () {},
              isFullscreen: false,
              onToggleFullscreen: () => fsTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('3 of 10'), findsOneWidget);

      await tester.tap(find.byTooltip('Next slide'));
      expect(nextTapped, isTrue);

      await tester.tap(find.byTooltip('Play slideshow'));
      expect(playTapped, isTrue);

      await tester.tap(find.byTooltip('Present slideshow'));
      expect(fsTapped, isTrue);
    });

    testWidgets('PresentationInfoSheet renders deck metadata accurately', (tester) async {
      const doc = PresentationDocument(
        title: 'PitchDeck_2026.pptx',
        filePath: '/mock/PitchDeck_2026.pptx',
        fileSizeBytes: 4194304,
        slides: [
          PresentationSlide(slideIndex: 0, shapes: [], speakerNotes: 'Note 1'),
          PresentationSlide(slideIndex: 1, shapes: []),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PresentationInfoSheet(document: doc),
          ),
        ),
      );

      expect(find.text('Presentation Information'), findsOneWidget);
      expect(find.text('PitchDeck_2026.pptx'), findsOneWidget);
      expect(find.text('16:9 Widescreen'), findsOneWidget);
      expect(find.text('1 of 2 slides'), findsOneWidget);
      expect(find.text('4.00 MB'), findsOneWidget);
    });

    testWidgets('PresentationSearchBar handles queries and match navigation', (tester) async {
      String query = '';
      bool nextMatch = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresentationSearchBar(
              totalMatches: 4,
              currentMatchIndex: 1,
              onQueryChanged: (q) => query = q,
              onPreviousMatch: () {},
              onNextMatch: () => nextMatch = true,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'revenue');
      expect(query, 'revenue');

      await tester.pump();
      expect(find.text('2 of 4 slides'), findsOneWidget);

      await tester.tap(find.byTooltip('Next match'));
      expect(nextMatch, isTrue);
    });
  });

  group('Strict Zero-Emoji Rule Validation for Phase 7', () {
    test('Ensures no emoji characters exist in presentation implementation files', () {
      final dir = Directory('lib/features/viewer');
      final files = dir.listSync(recursive: true).whereType<File>().where(
            (f) =>
                (f.path.contains('presentation') || f.path.contains('slide')) &&
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
