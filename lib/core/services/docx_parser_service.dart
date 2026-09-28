import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

/// Robust, 100% offline DOCX parser.
/// Unzips DOCX OpenXML packages and converts XML AST into structured [DocxDocument].
class DocxParserService {
  /// Parse a DOCX file from an absolute file path.
  static Future<DocxDocument> parseFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    final bytes = await file.readAsBytes();
    if (filePath.toLowerCase().endsWith('.doc') &&
        !filePath.toLowerCase().endsWith('.docx')) {
      return parseLegacyDoc(bytes);
    }

    // Run ZIP extraction and XML parsing in an Isolate for 60fps UI smoothness
    return compute(_parseDocxBytes, bytes);
  }

  /// Parse legacy binary .doc file by extracting text streams.
  static DocxDocument parseLegacyDoc(Uint8List bytes) {
    LoggerService.info('Parsing legacy .doc binary file');
    final textBuffer = StringBuffer();

    // Scan for printable ASCII sequences (minimum length 4)
    var currentRun = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      // Printable ASCII (32-126) plus newline (10), carriage return (13), tab (9)
      if ((b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9) {
        currentRun.add(b);
      } else {
        if (currentRun.length >= 4) {
          final str = String.fromCharCodes(currentRun).trim();
          if (str.length >= 4 && !str.startsWith('Microsoft') && !str.startsWith('Word.Document')) {
            textBuffer.writeln(str);
          }
        }
        currentRun = [];
      }
    }

    if (currentRun.length >= 4) {
      textBuffer.writeln(String.fromCharCodes(currentRun).trim());
    }

    final rawText = textBuffer.toString().trim();
    final paragraphs = rawText.split('\n');

    final blocks = <DocxBlock>[
      DocxParagraphBlock(
        runs: [
          DocxRun(
            text: 'Legacy Word Document (.doc)',
            isBold: true,
            fontSizePt: 18,
          ),
        ],
        style: DocxParagraphStyle.heading1,
      ),
      DocxParagraphBlock(
        runs: [
          DocxRun(
            text:
                'This file is in the legacy binary Word 97-2003 (.doc) format. Plain text has been extracted below. For full rich formatting, consider converting this file to .docx or opening with an external app.',
            color: Colors.grey.shade600,
            fontSizePt: 12,
          ),
        ],
        style: DocxParagraphStyle.quote,
      ),
    ];

    int words = 0;
    for (final p in paragraphs) {
      final clean = p.trim();
      if (clean.isEmpty) continue;
      words += clean.split(RegExp(r'\s+')).length;
      blocks.add(
        DocxParagraphBlock(
          runs: [DocxRun(text: clean, fontSizePt: 12)],
        ),
      );
    }

    return DocxDocument(
      blocks: blocks,
      headings: const [
        DocxHeading(
          id: 'heading-0',
          title: 'Legacy Word Document (.doc)',
          level: 1,
          blockIndex: 0,
        ),
      ],
      images: const {},
      wordCount: words,
      characterCount: rawText.length,
      estimatedReadingMinutes: (words / 200).ceil(),
    );
  }

  /// Worker function executed in isolate to parse DOCX OpenXML archive.
  static DocxDocument _parseDocxBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Locate word/document.xml
    ArchiveFile? docXmlFile;
    ArchiveFile? relsXmlFile;
    ArchiveFile? numXmlFile;

    final imageBytesMap = <String, Uint8List>{};

    for (final file in archive.files) {
      final norm = file.name.replaceAll(r'\', '/');
      if (norm == 'word/document.xml') {
        docXmlFile = file;
      } else if (norm == 'word/_rels/document.xml.rels') {
        relsXmlFile = file;
      } else if (norm == 'word/numbering.xml') {
        numXmlFile = file;
      } else if (norm.startsWith('word/media/')) {
        final key = norm.replaceFirst('word/', '');
        imageBytesMap[key] = Uint8List.fromList(file.content as List<int>);
        // Also map just the filename like 'image1.png'
        final baseName = key.split('/').last;
        imageBytesMap[baseName] = imageBytesMap[key]!;
      }
    }

    if (docXmlFile == null) {
      throw const FormatException('Invalid DOCX: missing word/document.xml');
    }

    // 2. Parse Relationships (rId -> Target)
    final relsMap = <String, String>{};
    if (relsXmlFile != null) {
      try {
        final relsXml = XmlDocument.parse(utf8.decode(relsXmlFile.content as List<int>, allowMalformed: true));
        for (final elem in relsXml.findAllElements('Relationship')) {
          final id = elem.getAttribute('Id');
          final target = elem.getAttribute('Target');
          if (id != null && target != null) {
            relsMap[id] = target;
          }
        }
      } on Object catch (_) {}
    }

    // 3. Parse Numbering formats (numId -> isBullet)
    final numIsBulletMap = <String, bool>{};
    if (numXmlFile != null) {
      try {
        final numXml = XmlDocument.parse(utf8.decode(numXmlFile.content as List<int>, allowMalformed: true));
        final abstractNumMap = <String, bool>{};

        for (final absElem in numXml.findAllElements('w:abstractNum')) {
          final absId = absElem.getAttribute('w:abstractNumId');
          if (absId == null) continue;
          bool isBullet = false;
          final numFmt = absElem.findAllElements('w:numFmt').firstOrNull;
          if (numFmt != null) {
            final val = numFmt.getAttribute('w:val');
            isBullet = val == 'bullet';
          }
          abstractNumMap[absId] = isBullet;
        }

        for (final numElem in numXml.findAllElements('w:num')) {
          final numId = numElem.getAttribute('w:numId');
          final absRef = numElem.findAllElements('w:abstractNumId').firstOrNull?.getAttribute('w:val');
          if (numId != null && absRef != null) {
            numIsBulletMap[numId] = abstractNumMap[absRef] ?? false;
          }
        }
      } on Object catch (_) {}
    }

    // 4. Parse word/document.xml
    final docXml = XmlDocument.parse(utf8.decode(docXmlFile.content as List<int>, allowMalformed: true));
    final bodyElem = docXml.findAllElements('w:body').firstOrNull;
    if (bodyElem == null) {
      return DocxDocument.empty();
    }

    final blocks = <DocxBlock>[];
    final headings = <DocxHeading>[];
    int totalWords = 0;
    int totalChars = 0;
    final listCounterMap = <String, int>{};

    for (final child in bodyElem.children.whereType<XmlElement>()) {
      if (child.name.local == 'p') {
        final hasPageBreak = child.descendants.whereType<XmlElement>().any((e) =>
            (e.name.local == 'br' && e.getAttribute('w:type') == 'page') ||
            e.name.local == 'lastRenderedPageBreak');

        final pBlock = _parseParagraph(
          child,
          relsMap,
          imageBytesMap,
          numIsBulletMap,
          listCounterMap,
          blocks.length,
        );
        if (pBlock != null) {
          blocks.add(pBlock);
          final text = pBlock.plainText;
          totalChars += text.length;
          if (text.trim().isNotEmpty) {
            totalWords += text.trim().split(RegExp(r'\s+')).length;
          }

          if (pBlock.style.isHeading && pBlock.plainText.trim().isNotEmpty) {
            headings.add(
              DocxHeading(
                id: pBlock.headingId ?? 'h_${headings.length}',
                title: pBlock.plainText.trim(),
                level: pBlock.style.headingLevel,
                blockIndex: blocks.length - 1,
              ),
            );
          }
        }
        if (hasPageBreak) {
          blocks.add(const DocxPageBreakBlock());
        }
      } else if (child.name.local == 'tbl') {
        final tBlock = _parseTable(child, relsMap, imageBytesMap);
        if (tBlock != null) {
          blocks.add(tBlock);
          for (final row in tBlock.rows) {
            for (final cell in row.cells) {
              final cellText = cell.plainText;
              totalChars += cellText.length;
              if (cellText.trim().isNotEmpty) {
                totalWords += cellText.trim().split(RegExp(r'\s+')).length;
              }
            }
          }
        }
      }
    }

    return DocxDocument(
      blocks: blocks,
      headings: headings,
      images: imageBytesMap,
      wordCount: totalWords,
      characterCount: totalChars,
      estimatedReadingMinutes: (totalWords / 200).ceil(),
    );
  }

  static DocxParagraphBlock? _parseParagraph(
    XmlElement pElem,
    Map<String, String> relsMap,
    Map<String, Uint8List> images,
    Map<String, bool> numIsBulletMap,
    Map<String, int> listCounterMap,
    int blockIndex,
  ) {
    // Check paragraph properties
    DocxParagraphStyle style = DocxParagraphStyle.normal;
    DocxAlignment alignment = DocxAlignment.left;
    bool isListItem = false;
    bool isBullet = false;
    int listIndex = 1;
    int listLevel = 0;
    String? headingId;

    final pPr = pElem.findElements('w:pPr').firstOrNull;
    if (pPr != null) {
      // Style
      final pStyle = pPr.findElements('w:pStyle').firstOrNull?.getAttribute('w:val');
      if (pStyle != null) {
        final sLower = pStyle.toLowerCase();
        if (sLower.contains('heading1') || sLower == '1') {
          style = DocxParagraphStyle.heading1;
          headingId = 'heading_$blockIndex';
        } else if (sLower.contains('heading2') || sLower == '2') {
          style = DocxParagraphStyle.heading2;
          headingId = 'heading_$blockIndex';
        } else if (sLower.contains('heading3') || sLower == '3') {
          style = DocxParagraphStyle.heading3;
          headingId = 'heading_$blockIndex';
        } else if (sLower.contains('heading4') || sLower == '4') {
          style = DocxParagraphStyle.heading4;
        } else if (sLower.contains('title')) {
          style = DocxParagraphStyle.title;
        } else if (sLower.contains('subtitle')) {
          style = DocxParagraphStyle.subtitle;
        } else if (sLower.contains('quote')) {
          style = DocxParagraphStyle.quote;
        } else if (sLower.contains('code')) {
          style = DocxParagraphStyle.code;
        }
      }

      // Alignment
      final jc = pPr.findElements('w:jc').firstOrNull?.getAttribute('w:val');
      if (jc != null) {
        switch (jc.toLowerCase()) {
          case 'center':
            alignment = DocxAlignment.center;
          case 'right':
            alignment = DocxAlignment.right;
          case 'both':
            alignment = DocxAlignment.justify;
          default:
            alignment = DocxAlignment.left;
        }
      }

      // List numbering
      final numPr = pPr.findElements('w:numPr').firstOrNull;
      if (numPr != null) {
        isListItem = true;
        final ilvlStr = numPr.findElements('w:ilvl').firstOrNull?.getAttribute('w:val');
        final numIdStr = numPr.findElements('w:numId').firstOrNull?.getAttribute('w:val');
        listLevel = int.tryParse(ilvlStr ?? '0') ?? 0;

        if (numIdStr != null) {
          isBullet = numIsBulletMap[numIdStr] ?? false;
          final key = '$numIdStr-$listLevel';
          final count = (listCounterMap[key] ?? 0) + 1;
          listCounterMap[key] = count;
          listIndex = count;
        }
      }
    }

    // Parse Runs and Hyperlinks
    final runs = <DocxRun>[];

    for (final node in pElem.children.whereType<XmlElement>()) {
      if (node.name.local == 'r') {
        final run = _parseRun(node, relsMap, images);
        if (run != null) runs.add(run);
      } else if (node.name.local == 'hyperlink') {
        final rId = node.getAttribute('r:id');
        final targetUrl = rId != null ? relsMap[rId] : null;
        for (final rNode in node.findElements('w:r')) {
          final run = _parseRun(rNode, relsMap, images, hyperlinkUrl: targetUrl);
          if (run != null) runs.add(run);
        }
      }
    }

    if (runs.isEmpty) {
      // Empty paragraph / spacer
      return DocxParagraphBlock(
        runs: const [DocxRun(text: '')],
        style: style,
        alignment: alignment,
        isListItem: isListItem,
        isBullet: isBullet,
        listIndex: listIndex,
        listLevel: listLevel,
        headingId: headingId,
      );
    }

    return DocxParagraphBlock(
      runs: runs,
      style: style,
      alignment: alignment,
      isListItem: isListItem,
      isBullet: isBullet,
      listIndex: listIndex,
      listLevel: listLevel,
      headingId: headingId,
    );
  }

  static DocxRun? _parseRun(
    XmlElement rElem,
    Map<String, String> relsMap,
    Map<String, Uint8List> images, {
    String? hyperlinkUrl,
  }) {
    // Check for inline images inside <w:drawing>
    final drawing = rElem.findElements('w:drawing').firstOrNull;
    if (drawing != null) {
      final blip = drawing.findAllElements('a:blip').firstOrNull;
      final embedId = blip?.getAttribute('r:embed');
      if (embedId != null && relsMap.containsKey(embedId)) {
        final target = relsMap[embedId]!;
        final imageKey = target.replaceAll(r'\', '/');

        // Extract dimension in EMU (1 pt = 12700 EMU)
        final extent = drawing.findAllElements('wp:extent').firstOrNull;
        double? widthPt;
        double? heightPt;
        if (extent != null) {
          final cx = int.tryParse(extent.getAttribute('cx') ?? '');
          final cy = int.tryParse(extent.getAttribute('cy') ?? '');
          if (cx != null) widthPt = cx / 12700.0;
          if (cy != null) heightPt = cy / 12700.0;
        }

        return DocxRun(
          text: '',
          imageKey: imageKey,
          imageWidth: widthPt,
          imageHeight: heightPt,
        );
      }
    }

    // Text content
    final tBuffer = StringBuffer();
    for (final child in rElem.children.whereType<XmlElement>()) {
      if (child.name.local == 't') {
        tBuffer.write(child.innerText);
      } else if (child.name.local == 'br') {
        tBuffer.write('\n');
      } else if (child.name.local == 'tab') {
        tBuffer.write('\t');
      }
    }

    final rawText = tBuffer.toString();
    if (rawText.isEmpty && drawing == null) {
      return null;
    }

    // Formatting properties <w:rPr>
    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    bool isStrike = false;
    Color? color;
    Color? highlightColor;
    double? fontSizePt;
    String? fontFamily;

    final rPr = rElem.findElements('w:rPr').firstOrNull;
    if (rPr != null) {
      // Bold
      final bElem = rPr.findElements('w:b').firstOrNull;
      if (bElem != null) {
        final val = bElem.getAttribute('w:val');
        isBold = val != '0' && val != 'false';
      }

      // Italic
      final iElem = rPr.findElements('w:i').firstOrNull;
      if (iElem != null) {
        final val = iElem.getAttribute('w:val');
        isItalic = val != '0' && val != 'false';
      }

      // Underline
      final uElem = rPr.findElements('w:u').firstOrNull;
      if (uElem != null) {
        final val = uElem.getAttribute('w:val');
        isUnderline = val != null && val != 'none';
      }

      // Strike
      final strikeElem = rPr.findElements('w:strike').firstOrNull;
      if (strikeElem != null) {
        final val = strikeElem.getAttribute('w:val');
        isStrike = val != '0' && val != 'false';
      }

      // Color
      final colorElem = rPr.findElements('w:color').firstOrNull;
      if (colorElem != null) {
        final hex = colorElem.getAttribute('w:val');
        if (hex != null && hex.toLowerCase() != 'auto') {
          color = _parseHexColor(hex);
        }
      }

      // Highlight
      final hlElem = rPr.findElements('w:highlight').firstOrNull;
      if (hlElem != null) {
        final val = hlElem.getAttribute('w:val');
        if (val != null && val != 'none') {
          highlightColor = _highlightColorFromName(val);
        }
      }

      // Font size (w:sz is half-points, e.g. 24 = 12pt)
      final szElem = rPr.findElements('w:sz').firstOrNull;
      if (szElem != null) {
        final halfPts = int.tryParse(szElem.getAttribute('w:val') ?? '');
        if (halfPts != null) {
          fontSizePt = halfPts / 2.0;
        }
      }

      // Font family
      final rFonts = rPr.findElements('w:rFonts').firstOrNull;
      if (rFonts != null) {
        fontFamily = rFonts.getAttribute('w:ascii') ?? rFonts.getAttribute('w:hAnsi');
      }
    }

    return DocxRun(
      text: rawText,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrike: isStrike,
      color: color,
      highlightColor: highlightColor,
      fontSizePt: fontSizePt,
      fontFamily: fontFamily,
      hyperlinkUrl: hyperlinkUrl,
    );
  }

  static DocxTableBlock? _parseTable(
    XmlElement tblElem,
    Map<String, String> relsMap,
    Map<String, Uint8List> images,
  ) {
    final rows = <DocxTableRow>[];

    final trElements = tblElem.findElements('w:tr').toList();
    for (int i = 0; i < trElements.length; i++) {
      final tr = trElements[i];
      final isHeader = i == 0 || tr.findAllElements('w:tblHeader').isNotEmpty;
      final cells = <DocxTableCell>[];

      for (final tc in tr.findElements('w:tc')) {
        Color? cellBg;
        int colSpan = 1;

        final tcPr = tc.findElements('w:tcPr').firstOrNull;
        if (tcPr != null) {
          final shd = tcPr.findElements('w:shd').firstOrNull;
          if (shd != null) {
            final fill = shd.getAttribute('w:fill');
            if (fill != null && fill.toLowerCase() != 'auto') {
              cellBg = _parseHexColor(fill);
            }
          }

          final gridSpan = tcPr.findElements('w:gridSpan').firstOrNull;
          if (gridSpan != null) {
            colSpan = int.tryParse(gridSpan.getAttribute('w:val') ?? '1') ?? 1;
          }
        }

        final cellParagraphs = <DocxParagraphBlock>[];
        for (final p in tc.findElements('w:p')) {
          final pBlock = _parseParagraph(
            p,
            relsMap,
            images,
            const {},
            {},
            0,
          );
          if (pBlock != null) cellParagraphs.add(pBlock);
        }

        cells.add(
          DocxTableCell(
            paragraphs: cellParagraphs,
            backgroundColor: cellBg,
            colSpan: colSpan,
          ),
        );
      }

      if (cells.isNotEmpty) {
        rows.add(DocxTableRow(cells: cells, isHeader: isHeader));
      }
    }

    if (rows.isEmpty) return null;
    return DocxTableBlock(rows: rows);
  }

  static Color? _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } on Object catch (_) {}
    return null;
  }

  static Color? _highlightColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'yellow':
        return Colors.yellow.withAlpha(120);
      case 'green':
        return Colors.lightGreen.withAlpha(120);
      case 'cyan':
        return Colors.cyan.withAlpha(120);
      case 'magenta':
        return Colors.pinkAccent.withAlpha(120);
      case 'blue':
        return Colors.lightBlue.withAlpha(120);
      case 'red':
        return Colors.redAccent.withAlpha(120);
      case 'darkyellow':
        return Colors.amber.withAlpha(120);
      case 'darkgray':
        return Colors.grey.withAlpha(120);
      case 'lightgray':
        return Colors.grey.shade300;
      default:
        return Colors.yellow.withAlpha(100);
    }
  }
}
