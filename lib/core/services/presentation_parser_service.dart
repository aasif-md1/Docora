import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

/// Parameters for background presentation parsing isolate.
class _PresentationParseParams {
  const _PresentationParseParams({
    required this.bytes,
    required this.filePath,
    required this.fileName,
  });

  final Uint8List bytes;
  final String filePath;
  final String fileName;
}

/// Structured presentation theme extracted from `ppt/theme/theme1.xml`.
class _PresentationTheme {
  const _PresentationTheme({
    required this.colors,
    this.majorFont = 'Calibri Light',
    this.minorFont = 'Calibri',
    this.defaultBackgroundColor = const Color(0xFFFFFFFF),
    this.defaultBackgroundGradient,
  });

  final Map<String, Color> colors;
  final String majorFont;
  final String minorFont;
  final Color defaultBackgroundColor;
  final List<Color>? defaultBackgroundGradient;
}

/// Parsed transform information containing normalized slide rect and rotation.
class _ParsedTransform {
  const _ParsedTransform({
    required this.rect,
    this.rotationDegrees,
  });

  final SlideRect rect;
  final double? rotationDegrees;
}

/// Context for coordinate mapping inside group shapes (`<p:grpSp>`).
class _GroupTransform {
  const _GroupTransform({
    required this.offX,
    required this.offY,
    required this.extCx,
    required this.extCy,
    required this.chOffX,
    required this.chOffY,
    required this.chExtCx,
    required this.chExtCy,
    this.rot,
  });

  final double offX;
  final double offY;
  final double extCx;
  final double extCy;
  final double chOffX;
  final double chOffY;
  final double chExtCx;
  final double chExtCy;
  final double? rot;

  math.Point<double> mapPoint(double x, double y) {
    final scaleX = chExtCx > 0 ? (extCx / chExtCx) : 1.0;
    final scaleY = chExtCy > 0 ? (extCy / chExtCy) : 1.0;
    return math.Point(
      offX + (x - chOffX) * scaleX,
      offY + (y - chOffY) * scaleY,
    );
  }

  math.Point<double> mapDimensions(double cx, double cy) {
    final scaleX = chExtCx > 0 ? (extCx / chExtCx) : 1.0;
    final scaleY = chExtCy > 0 ? (extCy / chExtCy) : 1.0;
    return math.Point(
      cx * scaleX,
      cy * scaleY,
    );
  }
}


/// Robust offline parser for PowerPoint presentations (.pptx and legacy .ppt).
/// Accurately extracts 2D slide coordinates, themes, gradients, backgrounds, tables, shapes, and typography.
class PresentationParserService {
  const PresentationParserService._();

  /// Parse a presentation file asynchronously.
  static Future<PresentationDocument> parseFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Presentation file does not exist', filePath);
    }

    final bytes = await file.readAsBytes();
    final fileName = filePath.replaceAll(r'\', '/').split('/').last;
    final ext = fileName.contains('.') ? '.${fileName.split('.').last.toLowerCase()}' : '';

    final params = _PresentationParseParams(
      bytes: bytes,
      filePath: filePath,
      fileName: fileName,
    );

    if (ext == '.ppt') {
      return _parseLegacyPpt(params);
    } else {
      return compute(_parsePptxIsolate, params);
    }
  }

  /// Parse PPTX OpenXML ZIP archive inside a background isolate.
  static PresentationDocument _parsePptxIsolate(_PresentationParseParams params) {
    try {
      final archive = ZipDecoder().decodeBytes(params.bytes);
      final filesMap = <String, ArchiveFile>{};
      for (final file in archive.files) {
        final norm = file.name.replaceAll(r'\', '/');
        filesMap[norm] = file;
        filesMap[norm.toLowerCase()] = file;
      }

      ArchiveFile? getArchiveFile(String path) {
        final norm = path.replaceAll(r'\', '/');
        return filesMap[norm] ?? filesMap[norm.toLowerCase()];
      }

      // 1. Parse theme color palette and typography from ppt/theme/theme1.xml
      final theme = _parseTheme(filesMap);
      final themeColors = theme.colors;

      // 2. Parse slide dimensions from ppt/presentation.xml (in EMUs)
      double slideWidthEmu = 18288000.0; // High-res widescreen default
      double slideHeightEmu = 10287000.0;
      final slideRelsMap = <String, String>{}; // rId -> slide path

      final presRelFile = getArchiveFile('ppt/_rels/presentation.xml.rels');
      if (presRelFile != null) {
        final relDoc = XmlDocument.parse(utf8.decode(presRelFile.content as List<int>, allowMalformed: true));
        for (final el in relDoc.findAllElements('Relationship')) {
          final id = el.getAttribute('Id');
          final target = el.getAttribute('Target');
          if (id != null && target != null) {
            String fullPath = target.startsWith('/') ? target.substring(1) : 'ppt/$target';
            if (!fullPath.startsWith('ppt/')) fullPath = 'ppt/$fullPath';
            slideRelsMap[id] = fullPath;
          }
        }
      }

      final orderedSlidePaths = <String>[];
      final presFile = getArchiveFile('ppt/presentation.xml');
      if (presFile != null) {
        final presDoc = XmlDocument.parse(utf8.decode(presFile.content as List<int>, allowMalformed: true));
        final sldSz = presDoc.findAllElements('p:sldSz').firstOrNull;
        if (sldSz != null) {
          final cx = double.tryParse(sldSz.getAttribute('cx') ?? '');
          final cy = double.tryParse(sldSz.getAttribute('cy') ?? '');
          if (cx != null && cy != null && cx > 0 && cy > 0) {
            slideWidthEmu = cx;
            slideHeightEmu = cy;
          }
        }

        // Extract ordered slides from <p:sldIdLst>
        for (final sldId in presDoc.findAllElements('p:sldId')) {
          final rId = sldId.getAttribute('r:id');
          if (rId != null && slideRelsMap.containsKey(rId)) {
            orderedSlidePaths.add(slideRelsMap[rId]!);
          }
        }
      }

      // Fallback: If no order list was found, discover all slide files
      if (orderedSlidePaths.isEmpty) {
        final discovered = filesMap.keys
            .where((k) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(k))
            .toSet()
            .toList();
        discovered.sort((a, b) {
          final numA = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '0') ?? 0;
          final numB = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '0') ?? 0;
          return numA.compareTo(numB);
        });
        orderedSlidePaths.addAll(discovered);
      }

      final slideWidth = slideWidthEmu / 9525.0;
      final slideHeight = slideHeightEmu / 9525.0;

      // 3. Parse individual slides
      final slides = <PresentationSlide>[];

      for (int i = 0; i < orderedSlidePaths.length; i++) {
        final slidePath = orderedSlidePaths[i];
        final slideFile = getArchiveFile(slidePath);
        if (slideFile == null) continue;

        final slideDoc = XmlDocument.parse(utf8.decode(slideFile.content as List<int>, allowMalformed: true));

        // Read slide relationships (images, notes, layout, diagrams)
        final slideFileName = slidePath.replaceAll(r'\', '/').split('/').last;
        final slideRelPath = 'ppt/slides/_rels/$slideFileName.rels';
        final slideRelFile = getArchiveFile(slideRelPath);
        final imageTargets = <String, String>{}; // rId -> target
        final slideRelTargets = <String, String>{}; // rId -> target
        String? notesSlideTarget;
        String? layoutTarget;

        if (slideRelFile != null) {
          final relDoc = XmlDocument.parse(utf8.decode(slideRelFile.content as List<int>, allowMalformed: true));
          for (final rel in relDoc.findAllElements('Relationship')) {
            final id = rel.getAttribute('Id');
            final type = rel.getAttribute('Type') ?? '';
            final target = rel.getAttribute('Target') ?? '';
            if (id != null) {
              String resolved = target;
              if (resolved.startsWith('../')) {
                resolved = 'ppt/${resolved.substring(3)}';
              } else if (!resolved.startsWith('ppt/')) {
                resolved = 'ppt/slides/$resolved';
              }
              slideRelTargets[id] = resolved;

              if (type.contains('image')) {
                imageTargets[id] = resolved;
              } else if (type.contains('notesSlide')) {
                notesSlideTarget = resolved;
              } else if (type.contains('slideLayout')) {
                layoutTarget = resolved;
              }
            }
          }
        }

        // Parse speaker notes if present
        String? speakerNotes;
        if (notesSlideTarget != null) {
          final notesFile = getArchiveFile(notesSlideTarget);
          if (notesFile != null) {
            speakerNotes = _parseSpeakerNotes(notesFile);
          }
        }

        // Parse layout document and layout relationships if present
        XmlDocument? layoutDoc;
        final layoutImageTargets = <String, String>{};
        String? masterTarget;

        if (layoutTarget != null) {
          final layoutFile = getArchiveFile(layoutTarget);
          if (layoutFile != null) {
            layoutDoc = XmlDocument.parse(utf8.decode(layoutFile.content as List<int>, allowMalformed: true));
            final layoutFileName = layoutTarget.replaceAll(r'\', '/').split('/').last;
            final layoutRelPath = 'ppt/slideLayouts/_rels/$layoutFileName.rels';
            final layoutRelFile = getArchiveFile(layoutRelPath);
            if (layoutRelFile != null) {
              final lRelDoc = XmlDocument.parse(utf8.decode(layoutRelFile.content as List<int>, allowMalformed: true));
              for (final rel in lRelDoc.findAllElements('Relationship')) {
                final id = rel.getAttribute('Id');
                final type = rel.getAttribute('Type') ?? '';
                final target = rel.getAttribute('Target') ?? '';
                if (id != null) {
                  if (type.contains('image')) {
                    String res = target;
                    if (res.startsWith('../')) res = 'ppt/${res.substring(3)}';
                    layoutImageTargets[id] = res;
                  } else if (type.contains('slideMaster')) {
                    String res = target;
                    if (res.startsWith('../')) res = 'ppt/${res.substring(3)}';
                    masterTarget = res;
                  }
                }
              }
            }
          }
        }

        // Parse master document and master relationships if present
        XmlDocument? masterDoc;
        final masterImageTargets = <String, String>{};

        if (masterTarget != null) {
          final masterFile = getArchiveFile(masterTarget);
          if (masterFile != null) {
            masterDoc = XmlDocument.parse(utf8.decode(masterFile.content as List<int>, allowMalformed: true));
            final masterFileName = masterTarget.replaceAll(r'\', '/').split('/').last;
            final masterRelPath = 'ppt/slideMasters/_rels/$masterFileName.rels';
            final masterRelFile = getArchiveFile(masterRelPath);
            if (masterRelFile != null) {
              final mRelDoc = XmlDocument.parse(utf8.decode(masterRelFile.content as List<int>, allowMalformed: true));
              for (final rel in mRelDoc.findAllElements('Relationship')) {
                final id = rel.getAttribute('Id');
                final type = rel.getAttribute('Type') ?? '';
                final target = rel.getAttribute('Target') ?? '';
                if (id != null) {
                  if (type.contains('image')) {
                    String res = target;
                    if (res.startsWith('../')) res = 'ppt/${res.substring(3)}';
                    masterImageTargets[id] = res;
                  }
                }
              }
            }
          }
        }

        // Extract slide background (4-tier cascade: Slide -> Layout -> Master -> Theme default)
        Uint8List? backgroundImageBytes;
        Color? backgroundColor;
        List<Color>? gradientColors;

        // Tier 1: Slide <p:bg>
        final slideBg = slideDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'bg').firstOrNull;
        if (slideBg != null) {
          gradientColors = _parseGradient(slideBg, themeColors);
          final blip = slideBg.descendants.whereType<XmlElement>().where((e) => e.name.local == 'blip').firstOrNull;
          final embedId = blip?.getAttribute('r:embed');
          if (embedId != null && imageTargets.containsKey(embedId)) {
            final bgFile = getArchiveFile(imageTargets[embedId]!);
            if (bgFile != null) {
              backgroundImageBytes = Uint8List.fromList(bgFile.content as List<int>);
            }
          }
          backgroundColor = _parseColor(slideBg, themeColors);
        }

        // Tier 2: Layout <p:bg> (if slide has no background override)
        if (gradientColors == null && backgroundImageBytes == null && backgroundColor == null && layoutDoc != null) {
          final layoutBg = layoutDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'bg').firstOrNull;
          if (layoutBg != null) {
            gradientColors = _parseGradient(layoutBg, themeColors);
            final blip = layoutBg.descendants.whereType<XmlElement>().where((e) => e.name.local == 'blip').firstOrNull;
            final embedId = blip?.getAttribute('r:embed');
            if (embedId != null && layoutImageTargets.containsKey(embedId)) {
              final bgFile = getArchiveFile(layoutImageTargets[embedId]!);
              if (bgFile != null) {
                backgroundImageBytes = Uint8List.fromList(bgFile.content as List<int>);
              }
            }
            backgroundColor = _parseColor(layoutBg, themeColors);
          }
        }

        // Tier 3: Master <p:bg> (if layout has no background override)
        if (gradientColors == null && backgroundImageBytes == null && backgroundColor == null && masterDoc != null) {
          final masterBg = masterDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'bg').firstOrNull;
          if (masterBg != null) {
            gradientColors = _parseGradient(masterBg, themeColors);
            final blip = masterBg.descendants.whereType<XmlElement>().where((e) => e.name.local == 'blip').firstOrNull;
            final embedId = blip?.getAttribute('r:embed');
            if (embedId != null && masterImageTargets.containsKey(embedId)) {
              final bgFile = getArchiveFile(masterImageTargets[embedId]!);
              if (bgFile != null) {
                backgroundImageBytes = Uint8List.fromList(bgFile.content as List<int>);
              }
            }
            backgroundColor = _parseColor(masterBg, themeColors);
          }
        }

        // Tier 4: Theme Default Background (fmtScheme or lt1 light color)
        if (gradientColors == null && backgroundImageBytes == null && backgroundColor == null) {
          gradientColors = theme.defaultBackgroundGradient;
          backgroundColor = theme.defaultBackgroundColor;
        }

        backgroundColor ??= gradientColors?.first ??
            theme.defaultBackgroundColor;

        // 4. Parse elements IN EXACT Z-INDEX ORDER
        final shapes = <SlideShape>[];
        final images = <SlideImage>[];
        final tables = <SlideTable>[];
        final visualElements = <SlideVisualElement>[];

        final cSld = slideDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'cSld').firstOrNull;
        final showMasterSpAttr = cSld?.getAttribute('showMasterSp');
        final showMasterSp = showMasterSpAttr != '0' && showMasterSpAttr != 'false';

        final layoutCSld = layoutDoc?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'cSld').firstOrNull;
        final layoutShowMasterSpAttr = layoutCSld?.getAttribute('showMasterSp');
        final layoutShowMaster = layoutShowMasterSpAttr != '0' && layoutShowMasterSpAttr != 'false';

        int shapeIdx = 0;

        // A. Master shapes (banners, header/footer branding) rendered behind slide content
        if (showMasterSp && masterDoc != null && layoutShowMaster) {
          final mSpTree = masterDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'spTree').firstOrNull;
          if (mSpTree != null) {
            shapeIdx = _appendTreeElements(
              elements: mSpTree.children.whereType<XmlElement>(),
              layoutDoc: null,
              imageTargets: masterImageTargets,
              getFile: getArchiveFile,
              slideWidthEmu: slideWidthEmu,
              slideHeightEmu: slideHeightEmu,
              theme: theme,
              shapes: shapes,
              images: images,
              tables: tables,
              visualElements: visualElements,
              startShapeIndex: shapeIdx,
              skipPlaceholders: true,
            );
          }
        }

        // B. Layout shapes
        if (showMasterSp && layoutDoc != null) {
          final lSpTree = layoutDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'spTree').firstOrNull;
          if (lSpTree != null) {
            shapeIdx = _appendTreeElements(
              elements: lSpTree.children.whereType<XmlElement>(),
              layoutDoc: null,
              imageTargets: layoutImageTargets,
              getFile: getArchiveFile,
              slideWidthEmu: slideWidthEmu,
              slideHeightEmu: slideHeightEmu,
              theme: theme,
              shapes: shapes,
              images: images,
              tables: tables,
              visualElements: visualElements,
              startShapeIndex: shapeIdx,
              skipPlaceholders: true,
            );
          }
        }

        // C. Slide's own content shapes
        final spTree = slideDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'spTree').firstOrNull;
        final treeChildren = spTree?.children.whereType<XmlElement>() ?? slideDoc.descendants.whereType<XmlElement>();

        shapeIdx = _appendTreeElements(
          elements: treeChildren,
          layoutDoc: layoutDoc,
          imageTargets: imageTargets,
          relTargets: slideRelTargets,
          getFile: getArchiveFile,
          slideWidthEmu: slideWidthEmu,
          slideHeightEmu: slideHeightEmu,
          theme: theme,
          shapes: shapes,
          images: images,
          tables: tables,
          visualElements: visualElements,
          startShapeIndex: shapeIdx,
          skipPlaceholders: false,
        );

        slides.add(
          PresentationSlide(
            slideIndex: i,
            shapes: shapes,
            images: images,
            tables: tables,
            elements: visualElements,
            gradientColors: gradientColors,
            backgroundImageBytes: backgroundImageBytes,
            backgroundColor: backgroundColor,
            speakerNotes: speakerNotes,
          ),
        );
      }

      return PresentationDocument(
        title: params.fileName,
        filePath: params.filePath,
        fileSizeBytes: params.bytes.length,
        slides: slides,
        slideWidth: slideWidth > 0 ? slideWidth : 960.0,
        slideHeight: slideHeight > 0 ? slideHeight : 540.0,
      );
    } on Object catch (e, stack) {
      LoggerService.error('Error parsing PPTX presentation: $e', error: e, stackTrace: stack);
      return PresentationDocument.empty(
        title: params.fileName,
        filePath: params.filePath,
      );
    }
  }

  /// Append elements from a `<p:spTree>` maintaining exact document z-order.
  /// If [skipPlaceholders] is true, elements containing `<p:ph>` are ignored (used for layout/master themes).
  static int _appendTreeElements({
    required Iterable<XmlElement> elements,
    required XmlDocument? layoutDoc,
    required Map<String, String> imageTargets,
    Map<String, String> relTargets = const {},
    required ArchiveFile? Function(String) getFile,
    required double slideWidthEmu,
    required double slideHeightEmu,
    required _PresentationTheme theme,
    required List<SlideShape> shapes,
    required List<SlideImage> images,
    required List<SlideTable> tables,
    required List<SlideVisualElement> visualElements,
    required int startShapeIndex,
    bool skipPlaceholders = false,
  }) {
    int shapeIdx = startShapeIndex;
    for (final child in elements) {
      if (skipPlaceholders) {
        final hasPh = child.descendants.whereType<XmlElement>().any((e) => e.name.local == 'ph');
        if (hasPh) continue;
      }

      final localName = child.name.local;

      // A. Standard Shape or Image-filled Shape <p:sp>
      if (localName == 'sp') {
        final blip = child.descendants.whereType<XmlElement>().where((e) => e.name.local == 'blip').firstOrNull;
        final embedId = blip?.getAttribute('r:embed');

        if (embedId != null && imageTargets.containsKey(embedId)) {
          final img = _parsePicture(child, imageTargets, getFile, slideWidthEmu, slideHeightEmu);
          if (img != null) {
            images.add(img);
            visualElements.add(SlideImageElement(image: img, rect: img.rect));
          }
        } else {
          final shape = _parseShape(child, layoutDoc, slideWidthEmu, slideHeightEmu, theme, shapeIdx++);
          if (shape != null) {
            shapes.add(shape);
            visualElements.add(SlideShapeElement(shape: shape, rect: shape.rect));
          }
        }
      }
      // B. Picture <p:pic>
      else if (localName == 'pic') {
        final img = _parsePicture(child, imageTargets, getFile, slideWidthEmu, slideHeightEmu);
        if (img != null) {
          images.add(img);
          visualElements.add(SlideImageElement(image: img, rect: img.rect));
        }
      }
      // C. Connector Line <p:cxnSp>
      else if (localName == 'cxnSp') {
        final line = _parseConnector(child, slideWidthEmu, slideHeightEmu, theme);
        if (line != null) {
          shapes.add(line);
          visualElements.add(SlideShapeElement(shape: line, rect: line.rect));
        }
      }
      // D. Graphic Frame / Table / Diagram <p:graphicFrame>
      else if (localName == 'graphicFrame') {
        final table = _parseGraphicFrameTable(child, slideWidthEmu, slideHeightEmu, theme);
        if (table != null) {
          tables.add(table);
          visualElements.add(SlideTableElement(table: table, rect: table.rect));
        } else {
          _parseGraphicFrameDiagram(
            gf: child,
            relTargets: relTargets,
            getFile: getFile,
            slideWidthEmu: slideWidthEmu,
            slideHeightEmu: slideHeightEmu,
            theme: theme,
            shapes: shapes,
            images: images,
            visualElements: visualElements,
          );
        }
      }
      // E. Group Shape / Diagrams / Flowcharts <p:grpSp>
      else if (localName == 'grpSp') {
        _parseGroupShape(
          child,
          layoutDoc,
          imageTargets,
          getFile,
          slideWidthEmu,
          slideHeightEmu,
          theme,
          shapes,
          images,
          visualElements,
          null,
        );
      }
    }
    return shapeIdx;
  }

  /// Parse SmartArt, Diagrams, and flowcharts from `<p:graphicFrame>`
  static void _parseGraphicFrameDiagram({
    required XmlElement gf,
    required Map<String, String> relTargets,
    required ArchiveFile? Function(String) getFile,
    required double slideWidthEmu,
    required double slideHeightEmu,
    required _PresentationTheme theme,
    required List<SlideShape> shapes,
    required List<SlideImage> images,
    required List<SlideVisualElement> visualElements,
  }) {
    try {
      final parsed = _parseTransform(gf, slideWidthEmu, slideHeightEmu);
      final bounds = parsed?.rect ?? const SlideRect(left: 0.08, top: 0.18, width: 0.84, height: 0.65);

      final relIds = gf.descendants.whereType<XmlElement>().where((e) => e.name.local == 'relIds').firstOrNull;
      final drawingRId = relIds?.getAttribute('r:drawing');
      final dataRId = relIds?.getAttribute('r:dm');

      // 1. Try drawingN.xml for full vector DrawingML presentation of the diagram
      if (drawingRId != null && relTargets.containsKey(drawingRId)) {
        final drawingPath = relTargets[drawingRId]!;
        final drawingFile = getFile(drawingPath);
        if (drawingFile != null) {
          final drawingDoc = XmlDocument.parse(utf8.decode(drawingFile.content as List<int>, allowMalformed: true));
          final spTree = drawingDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'spTree').firstOrNull;
          if (spTree != null) {
            final grpXfrm = spTree.descendants.whereType<XmlElement>().where((e) => e.name.local == 'xfrm').firstOrNull;
            final chOffX = double.tryParse(grpXfrm?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'chOff').firstOrNull?.getAttribute('x') ?? '0') ?? 0;
            final chOffY = double.tryParse(grpXfrm?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'chOff').firstOrNull?.getAttribute('y') ?? '0') ?? 0;
            final chExtCx = double.tryParse(grpXfrm?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'chExt').firstOrNull?.getAttribute('cx') ?? '1') ?? 1;
            final chExtCy = double.tryParse(grpXfrm?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'chExt').firstOrNull?.getAttribute('cy') ?? '1') ?? 1;

            final dgmTransform = _GroupTransform(
              offX: bounds.left * slideWidthEmu,
              offY: bounds.top * slideHeightEmu,
              extCx: bounds.width * slideWidthEmu,
              extCy: bounds.height * slideHeightEmu,
              chOffX: chOffX,
              chOffY: chOffY,
              chExtCx: chExtCx > 0 ? chExtCx : 1,
              chExtCy: chExtCy > 0 ? chExtCy : 1,
            );

            int dgmIdx = 0;
            for (final sp in spTree.descendants.whereType<XmlElement>().where((e) => e.name.local == 'sp')) {
              final shape = _parseShape(sp, null, slideWidthEmu, slideHeightEmu, theme, dgmIdx++, groupTransform: dgmTransform);
              if (shape != null) {
                shapes.add(shape);
                visualElements.add(SlideShapeElement(shape: shape, rect: shape.rect));
              }
            }
            return;
          }
        }
      }

      // 2. Fallback: Parse dataN.xml points into cleanly laid-out diagram node cards
      if (dataRId != null && relTargets.containsKey(dataRId)) {
        final dataPath = relTargets[dataRId]!;
        final dataFile = getFile(dataPath);
        if (dataFile != null) {
          final dataDoc = XmlDocument.parse(utf8.decode(dataFile.content as List<int>, allowMalformed: true));
          final ptLst = dataDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ptLst').firstOrNull;
          if (ptLst != null) {
            final nodePts = ptLst.children.whereType<XmlElement>().where((e) => e.name.local == 'pt' && e.getAttribute('type') == 'node').toList();
            if (nodePts.isNotEmpty) {
              final count = nodePts.length;
              final itemWidth = (bounds.width / count).clamp(0.12, 0.45);
              final gap = count > 1 ? ((bounds.width - (itemWidth * count)) / (count - 1)).clamp(0.01, 0.08) : 0.0;
              final accentPalette = [
                theme.colors['accent1'] ?? const Color(0xFF38BDF8),
                theme.colors['accent2'] ?? const Color(0xFF818CF8),
                theme.colors['accent3'] ?? const Color(0xFF34D399),
                theme.colors['accent4'] ?? const Color(0xFFFBBF24),
                theme.colors['accent5'] ?? const Color(0xFFF472B6),
                theme.colors['accent6'] ?? const Color(0xFF60A5FA),
              ];

              for (int k = 0; k < count; k++) {
                final pt = nodePts[k];
                final tNodes = pt.descendants.whereType<XmlElement>().where((e) => e.name.local == 't');
                final text = tNodes.map((t) => t.innerText.trim()).where((s) => s.isNotEmpty).join('\n');
                if (text.isEmpty) continue;

                final nodeLeft = bounds.left + k * (itemWidth + gap);
                final nodeColor = accentPalette[k % accentPalette.length];

                final shape = SlideShape(
                  rect: SlideRect(
                    left: nodeLeft,
                    top: bounds.top,
                    width: itemWidth,
                    height: bounds.height,
                  ),
                  backgroundColor: nodeColor.withAlpha(35),
                  borderColor: nodeColor,
                  borderWidth: 1.5,
                  borderRadius: 8.0,
                  anchorCenter: true,
                  shapeType: 'roundRect',
                  paragraphs: [
                    SlideParagraph(
                      alignment: TextAlign.center,
                      runs: [
                        SlideTextRun(
                          text: text,
                          fontSize: 16.0,
                          isBold: true,
                          color: nodeColor,
                          fontFamily: theme.majorFont,
                        ),
                      ],
                    ),
                  ],
                );
                shapes.add(shape);
                visualElements.add(SlideShapeElement(shape: shape, rect: shape.rect));
              }
              return;
            }
          }
        }
      }
    } on Object catch (_) {}
  }

  /// Parse gradient colors from `<a:gradFill>`.
  static List<Color>? _parseGradient(XmlElement parent, Map<String, Color> themeColors) {
    try {
      final gradFill = parent.descendants.whereType<XmlElement>().where((e) => e.name.local == 'gradFill').firstOrNull;
      if (gradFill == null) return null;

      final gsLst = gradFill.descendants.whereType<XmlElement>().where((e) => e.name.local == 'gsLst').firstOrNull;
      if (gsLst == null) return null;

      final colors = <Color>[];
      for (final gs in gsLst.children.whereType<XmlElement>()) {
        if (gs.name.local == 'gs') {
          final clr = _parseColor(gs, themeColors);
          if (clr != null) {
            colors.add(clr);
          }
        }
      }
      return colors.length >= 2 ? colors : null;
    } on Object catch (_) {
      return null;
    }
  }

  /// Parse full theme (colors, heading/body typography, default background) from `ppt/theme/theme1.xml`.
  static _PresentationTheme _parseTheme(Map<String, ArchiveFile> filesMap) {
    final colors = <String, Color>{};
    String majorFont = 'Calibri Light';
    String minorFont = 'Calibri';
    Color? defaultBgColor;
    List<Color>? defaultBgGradient;

    try {
      final themeFile = filesMap['ppt/theme/theme1.xml'];
      if (themeFile != null) {
        final doc = XmlDocument.parse(utf8.decode(themeFile.content as List<int>, allowMalformed: true));

        // 1. Color Scheme
        final clrScheme = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'clrScheme').firstOrNull;
        if (clrScheme != null) {
          for (final child in clrScheme.children.whereType<XmlElement>()) {
            final key = child.name.local; // dk1, lt1, dk2, lt2, accent1...
            final srgb = child.descendants.whereType<XmlElement>().where((e) => e.name.local == 'srgbClr').firstOrNull?.getAttribute('val');
            final sysClr = child.descendants.whereType<XmlElement>().where((e) => e.name.local == 'sysClr').firstOrNull?.getAttribute('lastClr');
            final hex = srgb ?? sysClr;
            if (hex != null && hex.length == 6) {
              final intVal = int.tryParse('FF$hex', radix: 16);
              if (intVal != null) {
                colors[key] = Color(intVal);
              }
            }
          }
        }

        // 2. Font Scheme (majorFont = headings, minorFont = body)
        final fontScheme = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'fontScheme').firstOrNull;
        if (fontScheme != null) {
          final maj = fontScheme.descendants.whereType<XmlElement>().where((e) => e.name.local == 'majorFont').firstOrNull;
          final min = fontScheme.descendants.whereType<XmlElement>().where((e) => e.name.local == 'minorFont').firstOrNull;
          final majLatin = maj?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'latin').firstOrNull?.getAttribute('typeface');
          final minLatin = min?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'latin').firstOrNull?.getAttribute('typeface');
          if (majLatin != null && majLatin.trim().isNotEmpty) majorFont = majLatin.trim();
          if (minLatin != null && minLatin.trim().isNotEmpty) minorFont = minLatin.trim();
        }

        // 3. Format Scheme (bgFillStyleLst for default background styling)
        final fmtScheme = doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'fmtScheme').firstOrNull;
        final bgFillList = fmtScheme?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'bgFillStyleLst').firstOrNull;
        if (bgFillList != null && bgFillList.children.whereType<XmlElement>().isNotEmpty) {
          final firstStyle = bgFillList.children.whereType<XmlElement>().first;
          defaultBgGradient = _parseGradient(firstStyle, colors);
          defaultBgColor = _parseColor(firstStyle, colors);
        }
      }
    } on Object catch (_) {}

    // Ensure fallback theme defaults
    colors.putIfAbsent('dk1', () => const Color(0xFF000000));
    colors.putIfAbsent('lt1', () => const Color(0xFFFFFFFF));
    colors.putIfAbsent('dk2', () => const Color(0xFF1F497D));
    colors.putIfAbsent('lt2', () => const Color(0xFFEEECE1));
    colors.putIfAbsent('accent1', () => const Color(0xFF4F81BD));
    colors.putIfAbsent('accent2', () => const Color(0xFFC0504D));
    colors.putIfAbsent('accent3', () => const Color(0xFF9BBB59));
    colors.putIfAbsent('accent4', () => const Color(0xFF8064A2));
    colors.putIfAbsent('accent5', () => const Color(0xFF4BACC6));
    colors.putIfAbsent('accent6', () => const Color(0xFFF79646));

    // Standard Office background is light (lt1), not dark
    defaultBgColor ??= colors['lt1'] ?? const Color(0xFFFFFFFF);

    return _PresentationTheme(
      colors: colors,
      majorFont: majorFont,
      minorFont: minorFont,
      defaultBackgroundColor: defaultBgColor,
      defaultBackgroundGradient: defaultBgGradient,
    );
  }


  /// Parse transform `<a:xfrm>` into normalized [_ParsedTransform] (including rotation and group transform mapping).
  static _ParsedTransform? _parseTransform(
    XmlElement elem,
    double slideWidthEmu,
    double slideHeightEmu, {
    _GroupTransform? groupTransform,
  }) {
    try {
      final xfrm = elem.descendants.whereType<XmlElement>().where((e) => e.name.local == 'xfrm').firstOrNull;
      if (xfrm == null) return null;

      final off = xfrm.descendants.whereType<XmlElement>().where((e) => e.name.local == 'off').firstOrNull;
      final ext = xfrm.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ext').firstOrNull;

      double? x = double.tryParse(off?.getAttribute('x') ?? '');
      double? y = double.tryParse(off?.getAttribute('y') ?? '');
      double? cx = double.tryParse(ext?.getAttribute('cx') ?? '');
      double? cy = double.tryParse(ext?.getAttribute('cy') ?? '');

      if (x == null || y == null || cx == null || cy == null) return null;

      double? rot;
      final rotAttr = xfrm.getAttribute('rot');
      if (rotAttr != null) {
        final rotVal = double.tryParse(rotAttr);
        if (rotVal != null) {
          rot = (rotVal / 60000.0) % 360.0;
        }
      }

      if (groupTransform != null) {
        final pt = groupTransform.mapPoint(x, y);
        final dim = groupTransform.mapDimensions(cx, cy);
        x = pt.x;
        y = pt.y;
        cx = dim.x;
        cy = dim.y;
        if (groupTransform.rot != null) {
          rot = ((rot ?? 0) + groupTransform.rot!) % 360.0;
        }
      }

      if (slideWidthEmu > 0 && slideHeightEmu > 0) {
        return _ParsedTransform(
          rect: SlideRect(
            left: x / slideWidthEmu,
            top: y / slideHeightEmu,
            width: (cx / slideWidthEmu).abs(),
            height: (cy / slideHeightEmu).abs(),
          ),
          rotationDegrees: rot,
        );
      }
    } on Object catch (_) {}
    return null;
  }


  /// Extracts DrawingML alpha value (alpha, alphaMod, alphaOff, alphaModFix) as normalized 0.0 .. 1.0.
  static double? _extractAlphaValue(XmlElement? node) {
    if (node == null) return null;
    final alphaElem = (node.name.local == 'alpha' ||
            node.name.local == 'alphaMod' ||
            node.name.local == 'alphaOff' ||
            node.name.local == 'alphaModFix')
        ? node
        : node.descendants.whereType<XmlElement>().where((e) =>
            e.name.local == 'alpha' ||
            e.name.local == 'alphaMod' ||
            e.name.local == 'alphaOff' ||
            e.name.local == 'alphaModFix').firstOrNull;

    if (alphaElem == null) return null;
    final raw = alphaElem.getAttribute('val') ?? alphaElem.getAttribute('amt');
    if (raw == null || raw.trim().isEmpty) return null;

    final clean = raw.trim().replaceAll('%', '');
    final v = double.tryParse(clean);
    if (v == null) return null;
    if (raw.contains('%')) return (v / 100.0).clamp(0.0, 1.0);
    if (v <= 1.0) return v.clamp(0.0, 1.0);
    if (v <= 100.0) return (v / 100.0).clamp(0.0, 1.0);
    return (v / 100000.0).clamp(0.0, 1.0);
  }

  /// Applies DrawingML color modulations (lumMod, lumOff, tint, shade, alpha, alphaMod) to match PowerPoint rendering fidelity.
  static Color _applyColorModulations(Color color, XmlElement node) {
    double r = color.r;
    double g = color.g;
    double b = color.b;
    double a = color.a;

    final alphaVal = _extractAlphaValue(node);
    if (alphaVal != null) {
      a = a * alphaVal;
    }

    final tintNode = node.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tint').firstOrNull;
    final shadeNode = node.descendants.whereType<XmlElement>().where((e) => e.name.local == 'shade').firstOrNull;
    final lumModNode = node.descendants.whereType<XmlElement>().where((e) => e.name.local == 'lumMod').firstOrNull;
    final lumOffNode = node.descendants.whereType<XmlElement>().where((e) => e.name.local == 'lumOff').firstOrNull;

    if (tintNode != null) {
      final tintVal = double.tryParse(tintNode.getAttribute('val') ?? '');
      if (tintVal != null) {
        final t = (tintVal / 100000.0).clamp(0.0, 1.0);
        r = r * t + (1.0 - t);
        g = g * t + (1.0 - t);
        b = b * t + (1.0 - t);
      }
    }

    if (shadeNode != null) {
      final shadeVal = double.tryParse(shadeNode.getAttribute('val') ?? '');
      if (shadeVal != null) {
        final s = (shadeVal / 100000.0).clamp(0.0, 1.0);
        r = r * s;
        g = g * s;
        b = b * s;
      }
    }

    if (lumModNode != null || lumOffNode != null) {
      final mod = (double.tryParse(lumModNode?.getAttribute('val') ?? '100000') ?? 100000) / 100000.0;
      final off = (double.tryParse(lumOffNode?.getAttribute('val') ?? '0') ?? 0) / 100000.0;
      final hsl = HSLColor.fromColor(Color.from(alpha: a.clamp(0.0, 1.0), red: r.clamp(0.0, 1.0), green: g.clamp(0.0, 1.0), blue: b.clamp(0.0, 1.0)));
      final newLightness = (hsl.lightness * mod + off).clamp(0.0, 1.0);
      return hsl.withLightness(newLightness).toColor();
    }

    return Color.from(alpha: a.clamp(0.0, 1.0), red: r.clamp(0.0, 1.0), green: g.clamp(0.0, 1.0), blue: b.clamp(0.0, 1.0));
  }

  /// Extract RGB or theme color from an XML node, with alpha/opacity support and color modulations.
  static Color? _parseColor(XmlElement? parent, Map<String, Color> themeColors) {
    if (parent == null) return null;
    try {
      final parentAlpha = _extractAlphaValue(parent);
      Color? baseColor;

      // 1. srgbClr (exact hex)
      final srgb = parent.descendants.whereType<XmlElement>().where((e) => e.name.local == 'srgbClr').firstOrNull;
      if (srgb != null) {
        final val = srgb.getAttribute('val');
        if (val != null && val.length == 6) {
          final hex = int.tryParse('FF$val', radix: 16);
          if (hex != null) baseColor = _applyColorModulations(Color(hex), srgb);
        }
      }

      // 2. schemeClr (theme preset)
      if (baseColor == null) {
        final scheme = parent.descendants.whereType<XmlElement>().where((e) => e.name.local == 'schemeClr').firstOrNull;
        if (scheme != null) {
          final val = scheme.getAttribute('val') ?? '';
          Color? resolved;

          // Standard OpenXML scheme mapping
          if (val == 'tx1') {
            resolved = themeColors['dk1'] ?? const Color(0xFF000000);
          } else if (val == 'tx2') {
            resolved = themeColors['dk2'] ?? const Color(0xFF1F497D);
          } else if (val == 'bg1') {
            resolved = themeColors['lt1'] ?? const Color(0xFFFFFFFF);
          } else if (val == 'bg2') {
            resolved = themeColors['lt2'] ?? const Color(0xFFEEECE1);
          } else if (val == 'dk1') {
            resolved = themeColors['dk1'] ?? const Color(0xFF000000);
          } else if (val == 'lt1') {
            resolved = themeColors['lt1'] ?? const Color(0xFFFFFFFF);
          } else if (val == 'dk2') {
            resolved = themeColors['dk2'] ?? const Color(0xFF1F497D);
          } else if (val == 'lt2') {
            resolved = themeColors['lt2'] ?? const Color(0xFFEEECE1);
          } else if (themeColors.containsKey(val)) {
            resolved = themeColors[val];
          } else {
            switch (val) {
              case 'accent1':
                resolved = const Color(0xFF38BDF8);
                break;
              case 'accent2':
                resolved = const Color(0xFF818CF8);
                break;
              case 'accent3':
                resolved = const Color(0xFF34D399);
                break;
              case 'accent4':
                resolved = const Color(0xFFFBBF24);
                break;
              case 'accent5':
                resolved = const Color(0xFFF472B6);
                break;
              case 'accent6':
                resolved = const Color(0xFF60A5FA);
                break;
              case 'hlink':
                resolved = const Color(0xFF38BDF8);
                break;
            }
          }

          if (resolved != null) {
            baseColor = _applyColorModulations(resolved, scheme);
          }
        }
      }

      // 3. sysClr (system color preset)
      if (baseColor == null) {
        final sysClr = parent.descendants.whereType<XmlElement>().where((e) => e.name.local == 'sysClr').firstOrNull;
        if (sysClr != null) {
          final lastClr = sysClr.getAttribute('lastClr');
          if (lastClr != null && lastClr.length == 6) {
            final hex = int.tryParse('FF$lastClr', radix: 16);
            if (hex != null) baseColor = _applyColorModulations(Color(hex), sysClr);
          }
        }
      }

      // 4. bgRef (theme background reference)
      if (baseColor == null) {
        final bgRef = parent.descendants.whereType<XmlElement>().where((e) => e.name.local == 'bgRef').firstOrNull;
        if (bgRef != null) {
          final scheme = bgRef.descendants.whereType<XmlElement>().where((e) => e.name.local == 'schemeClr').firstOrNull;
          if (scheme != null) {
            final val = scheme.getAttribute('val') ?? '';
            final clr = themeColors[val] ?? themeColors['lt1'];
            if (clr != null) {
              baseColor = _applyColorModulations(clr, scheme);
            }
          }
        }
      }

      if (baseColor != null) {
        if (parentAlpha != null) {
          final finalAlpha = (baseColor.a * parentAlpha).clamp(0.0, 1.0);
          return baseColor.withValues(alpha: finalAlpha);
        }
        return baseColor;
      }
    } on Object catch (_) {}
    return null;
  }

  /// Parse a slide shape `<p:sp>` into a `SlideShape`.
  static SlideShape? _parseShape(
    XmlElement sp,
    XmlDocument? layoutDoc,
    double slideWidthEmu,
    double slideHeightEmu,
    _PresentationTheme theme,
    int shapeIndex, {
    _GroupTransform? groupTransform,
  }) {
    final themeColors = theme.colors;
    final parsed = _parseTransform(sp, slideWidthEmu, slideHeightEmu, groupTransform: groupTransform);
    SlideRect? rect = parsed?.rect;
    final rotationDegrees = parsed?.rotationDegrees;

    // Check placeholder title
    bool isTitle = false;
    String phType = '';
    final ph = sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ph').firstOrNull;
    if (ph != null) {
      phType = ph.getAttribute('type') ?? '';
      if (phType == 'title' || phType == 'ctrTitle' || phType == 'subTitle') {
        isTitle = true;
      }
    }

    // Also detect heading by position (top 28%) and large font size
    if (!isTitle && rect != null && rect.top <= 0.28 && rect.height <= 0.35) {
      final hasLargeFont = sp.descendants.whereType<XmlElement>().any((e) {
        if (e.name.local == 'rPr') {
          final sz = double.tryParse(e.getAttribute('sz') ?? '0') ?? 0;
          return sz >= 2200;
        }
        return false;
      });
      if (hasLargeFont) {
        isTitle = true;
      }
    }

    // If placeholder has no transform in slide, inherit from layout
    if (rect == null && ph != null) {
      if (layoutDoc != null) {
        for (final lSp in layoutDoc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'sp')) {
          final lPh = lSp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ph').firstOrNull;
          if (lPh?.getAttribute('type') == phType) {
            rect = _parseTransform(lSp, slideWidthEmu, slideHeightEmu)?.rect;
            if (rect != null) break;
          }
        }
      }

      if (rect == null) {
        if (phType == 'ctrTitle' || phType == 'title') {
          rect = const SlideRect(left: 0.05, top: 0.22, width: 0.90, height: 0.22);
        } else if (phType == 'subTitle') {
          rect = const SlideRect(left: 0.10, top: 0.46, width: 0.80, height: 0.14);
        } else if (phType == 'body') {
          rect = const SlideRect(left: 0.08, top: 0.26, width: 0.84, height: 0.62);
        }
      }
    }

    // Default stagger for unpositioned shapes
    rect ??= SlideRect(
      left: 0.06,
      top: (0.12 + (shapeIndex * 0.16)).clamp(0.05, 0.82),
      width: 0.88,
      height: 0.14,
    );

    // Check shape properties (background fill, gradient fill, border, geometry)
    Color? backgroundColor;
    List<Color>? gradientColors;
    Color? borderColor;
    double? borderWidth;
    double? borderRadius;
    String? shapeType;
    List<String>? customPathCommands;

    final spPr = sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'spPr').firstOrNull;
    final hasNoFill = spPr?.children.whereType<XmlElement>().any((e) => e.name.local == 'noFill') ?? false;

    if (spPr != null) {
      if (!hasNoFill) {
        final solidFill = spPr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'solidFill').firstOrNull;
        if (solidFill != null) {
          backgroundColor = _parseColor(solidFill, themeColors);
        }

        final gradFill = spPr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'gradFill').firstOrNull;
        if (gradFill != null) {
          gradientColors = _parseGradient(spPr, themeColors);
        }
      }

      // Check shape-level transparency / effects (<a:alphaModFix>, <a:alpha>, etc.)
      final shapeLevelAlpha = _extractAlphaValue(spPr);
      if (shapeLevelAlpha != null) {
        if (backgroundColor != null) {
          backgroundColor = backgroundColor.withValues(alpha: (backgroundColor.a * shapeLevelAlpha).clamp(0.0, 1.0));
        }
        if (gradientColors != null) {
          gradientColors = gradientColors.map((c) => c.withValues(alpha: (c.a * shapeLevelAlpha).clamp(0.0, 1.0))).toList();
        }
      }

      final ln = spPr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ln').firstOrNull;
      if (ln != null) {
        borderColor = _parseColor(ln, themeColors);
        final wStr = ln.getAttribute('w');
        if (wStr != null) {
          final wVal = double.tryParse(wStr);
          if (wVal != null && wVal > 0) {
            borderWidth = (wVal / 12700.0).clamp(0.5, 6.0);
          }
        }
      }

      final geom = spPr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'prstGeom').firstOrNull;
      final prst = geom?.getAttribute('prst');
      shapeType = prst;
      if (prst == 'roundRect' || prst == 'round2DiagRect' || prst == 'round2SameRect' || prst == 'round1Rect') {
        borderRadius = 8.0;
      }

      // Parse custom geometry DrawingML vector paths
      customPathCommands = _parseCustomGeometry(spPr);
    }

    // Resolve shape style references from <p:style> (fillRef, lnRef)
    final styleNode = sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'style').firstOrNull;
    if (styleNode != null) {
      if (!hasNoFill && backgroundColor == null && gradientColors == null) {
        final fillRef = styleNode.descendants.whereType<XmlElement>().where((e) => e.name.local == 'fillRef').firstOrNull;
        if (fillRef != null) {
          final idx = int.tryParse(fillRef.getAttribute('idx') ?? '0') ?? 0;
          // In OpenXML fmtScheme: idx=0 means NO FILL!
          if (idx > 0) {
            final clr = _parseColor(fillRef, themeColors) ??
                themeColors['accent$idx'] ??
                themeColors['accent1'];
            if (clr != null) {
              final refAlpha = _extractAlphaValue(fillRef);
              if (refAlpha != null) {
                backgroundColor = clr.withValues(alpha: refAlpha);
              } else {
                backgroundColor = clr;
              }
            }
          }
        }
      }
      if (borderColor == null) {
        final lnRef = styleNode.descendants.whereType<XmlElement>().where((e) => e.name.local == 'lnRef').firstOrNull;
        if (lnRef != null) {
          borderColor = _parseColor(lnRef, themeColors);
          final idx = int.tryParse(lnRef.getAttribute('idx') ?? '0') ?? 0;
          if (borderColor == null && idx > 0) {
            borderColor = themeColors['accent$idx'] ?? themeColors['accent1'];
          }
        }
      }
    }

    // If explicit geometry exists without color and without noFill, use subtle accent so shape isn't invisible
    final hasExplicitGeometry = (shapeType != null && shapeType != 'rect') || customPathCommands != null;
    if (!hasNoFill && hasExplicitGeometry && backgroundColor == null && borderColor == null && gradientColors == null) {
      final accent = themeColors['accent1'] ?? const Color(0xFF2563EB);
      backgroundColor = accent.withValues(alpha: 0.18);
      borderColor = accent.withValues(alpha: 0.6);
      borderWidth ??= 1.2;
    }

    final bodyPr = sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'bodyPr').firstOrNull;
    final anchorCenter = bodyPr?.getAttribute('anchor') == 'ctr';

    // Base coordinate normalization: 960 base width vs slideWidthPoints
    final slideWidthPoints = slideWidthEmu / 9525.0;
    final fontScale = (slideWidthPoints > 0) ? (960.0 / slideWidthPoints) : 1.0;

    // Parse text body with typography scheme inheritance
    final txBody = sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'txBody').firstOrNull;
    final paragraphs = txBody != null
        ? _parseTxBody(txBody, theme, fontScale: fontScale, isTitle: isTitle)
        : <SlideParagraph>[];

    // Do NOT drop explicit shapes even if they have no text
    if (paragraphs.isEmpty &&
        backgroundColor == null &&
        gradientColors == null &&
        borderColor == null &&
        shapeType == null &&
        customPathCommands == null) {
      return null;
    }

    return SlideShape(
      paragraphs: paragraphs,
      title: isTitle,
      rect: rect,
      backgroundColor: backgroundColor,
      gradientColors: gradientColors,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      anchorCenter: anchorCenter,
      shapeType: shapeType,
      rotationDegrees: rotationDegrees,
      customPathCommands: customPathCommands,
    );
  }

  /// Parse custom vector path from DrawingML `<a:custGeom>`.
  static List<String>? _parseCustomGeometry(XmlElement spPr) {
    try {
      final custGeom = spPr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'custGeom').firstOrNull;
      if (custGeom == null) return null;

      final pathElem = custGeom.descendants.whereType<XmlElement>().where((e) => e.name.local == 'path').firstOrNull;
      if (pathElem == null) return null;

      // Standard DrawingML shape coordinate grid is 21600x21600 if attributes are omitted
      final w = double.tryParse(pathElem.getAttribute('w') ?? '21600') ?? 21600.0;
      final h = double.tryParse(pathElem.getAttribute('h') ?? '21600') ?? 21600.0;
      if (w <= 0 || h <= 0) return null;

      final commands = <String>[];
      commands.add('VIEWBOX $w $h');

      for (final cmd in pathElem.children.whereType<XmlElement>()) {
        final name = cmd.name.local;
        if (name == 'moveTo') {
          final pt = cmd.descendants.whereType<XmlElement>().where((e) => e.name.local == 'pt').firstOrNull;
          if (pt != null) {
            final x = pt.getAttribute('x') ?? '0';
            final y = pt.getAttribute('y') ?? '0';
            commands.add('M $x $y');
          }
        } else if (name == 'lnTo') {
          final pt = cmd.descendants.whereType<XmlElement>().where((e) => e.name.local == 'pt').firstOrNull;
          if (pt != null) {
            final x = pt.getAttribute('x') ?? '0';
            final y = pt.getAttribute('y') ?? '0';
            commands.add('L $x $y');
          }
        } else if (name == 'cubicBezTo') {
          final pts = cmd.descendants.whereType<XmlElement>().where((e) => e.name.local == 'pt').toList();
          if (pts.length >= 3) {
            final x1 = pts[0].getAttribute('x') ?? '0';
            final y1 = pts[0].getAttribute('y') ?? '0';
            final x2 = pts[1].getAttribute('x') ?? '0';
            final y2 = pts[1].getAttribute('y') ?? '0';
            final x3 = pts[2].getAttribute('x') ?? '0';
            final y3 = pts[2].getAttribute('y') ?? '0';
            commands.add('C $x1 $y1 $x2 $y2 $x3 $y3');
          }
        } else if (name == 'quadBezTo') {
          final pts = cmd.descendants.whereType<XmlElement>().where((e) => e.name.local == 'pt').toList();
          if (pts.length >= 2) {
            final x1 = pts[0].getAttribute('x') ?? '0';
            final y1 = pts[0].getAttribute('y') ?? '0';
            final x2 = pts[1].getAttribute('x') ?? '0';
            final y2 = pts[1].getAttribute('y') ?? '0';
            commands.add('Q $x1 $y1 $x2 $y2');
          }
        } else if (name == 'arcTo') {
          final wR = double.tryParse(cmd.getAttribute('wR') ?? '0') ?? 0;
          final hR = double.tryParse(cmd.getAttribute('hR') ?? '0') ?? 0;
          final stAng = (double.tryParse(cmd.getAttribute('stAng') ?? '0') ?? 0) / 60000.0;
          final swAng = (double.tryParse(cmd.getAttribute('swAng') ?? '0') ?? 0) / 60000.0;
          commands.add('A $wR $hR $stAng $swAng');
        } else if (name == 'close') {
          commands.add('Z');
        }
      }
      return commands.isNotEmpty ? commands : null;
    } catch (_) {
      return null;
    }
  }

  /// Parse connector line `<p:cxnSp>`.
  static SlideShape? _parseConnector(
    XmlElement cxn,
    double slideWidthEmu,
    double slideHeightEmu,
    _PresentationTheme theme, {
    _GroupTransform? groupTransform,
  }) {
    final themeColors = theme.colors;
    final parsed = _parseTransform(cxn, slideWidthEmu, slideHeightEmu, groupTransform: groupTransform);
    final rect = parsed?.rect;
    final rot = parsed?.rotationDegrees;
    final spPr = cxn.descendants.whereType<XmlElement>().where((e) => e.name.local == 'spPr').firstOrNull;
    final ln = spPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ln').firstOrNull;
    final color = _parseColor(ln, themeColors) ?? Colors.white.withAlpha(120);

    return SlideShape(
      paragraphs: const [],
      rect: rect,
      borderColor: color,
      borderWidth: 1.2,
      isLine: true,
      rotationDegrees: rot,
    );
  }

  /// Parse table from `<p:graphicFrame>` (e.g. multi-column attribution).
  static SlideTable? _parseGraphicFrameTable(
    XmlElement gf,
    double slideWidthEmu,
    double slideHeightEmu,
    _PresentationTheme theme,
  ) {
    try {
      final themeColors = theme.colors;
      final rect = _parseTransform(gf, slideWidthEmu, slideHeightEmu)?.rect ??
          const SlideRect(left: 0.06, top: 0.62, width: 0.88, height: 0.22);

      final tbl = gf.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tbl').firstOrNull;
      if (tbl == null) return null;

      final colRatios = <double>[];
      double totalColsWidth = 0;
      final gridCols = tbl.descendants.whereType<XmlElement>().where((e) => e.name.local == 'gridCol').toList();
      for (final col in gridCols) {
        final w = double.tryParse(col.getAttribute('w') ?? '1') ?? 1.0;
        colRatios.add(w);
        totalColsWidth += w;
      }
      if (totalColsWidth > 0) {
        for (int i = 0; i < colRatios.length; i++) {
          colRatios[i] = colRatios[i] / totalColsWidth;
        }
      }

      final rows = <SlideTableRow>[];
      final trList = tbl.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tr').toList();
      for (final tr in trList) {
        final cells = <SlideTableCell>[];
        final tcList = tr.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tc').toList();

        final slideWidthPoints = slideWidthEmu / 9525.0;
        final fontScale = (slideWidthPoints > 0) ? (960.0 / slideWidthPoints) : 1.0;

        for (final tc in tcList) {
          final txBody = tc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'txBody').firstOrNull;
          final paragraphs = txBody != null ? _parseTxBody(txBody, theme, fontScale: fontScale) : <SlideParagraph>[];

          final tcPr = tc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'tcPr').firstOrNull;
          final cellBg = _parseColor(tcPr, themeColors);
          final cellBorder = _parseColor(tcPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ln').firstOrNull, themeColors);

          cells.add(SlideTableCell(
            paragraphs: paragraphs,
            backgroundColor: cellBg,
            borderColor: cellBorder,
          ));
        }

        if (cells.isNotEmpty) {
          rows.add(SlideTableRow(cells: cells));
        }
      }

      if (rows.isEmpty) return null;

      return SlideTable(
        rows: rows,
        rect: rect,
        columnWidthRatios: colRatios.isNotEmpty ? colRatios : null,
      );
    } on Object catch (_) {
      return null;
    }
  }

  /// Parse text body `<a:txBody>` into structured `SlideParagraph`s.
  static List<SlideParagraph> _parseTxBody(
    XmlElement txBody,
    _PresentationTheme theme, {
    double fontScale = 1.0,
    bool isTitle = false,
  }) {
    final themeColors = theme.colors;
    final paragraphs = <SlideParagraph>[];
    final pNodes = txBody.descendants.whereType<XmlElement>().where((e) => e.name.local == 'p').toList();

    for (final pNode in pNodes) {
      final pPr = pNode.descendants.whereType<XmlElement>().where((e) => e.name.local == 'pPr').firstOrNull;
      final lvlStr = pPr?.getAttribute('lvl');
      final level = lvlStr != null ? (int.tryParse(lvlStr) ?? 0) : 0;
      final isBullet = level > 0 || pPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'buChar').isNotEmpty == true;

      final algn = pPr?.getAttribute('algn') ?? '';
      TextAlign alignment = TextAlign.left;
      if (algn == 'ctr') alignment = TextAlign.center;
      if (algn == 'r') alignment = TextAlign.right;
      if (algn == 'just') alignment = TextAlign.justify;

      final defRPr = pPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'defRPr').firstOrNull;
      double? defaultFontSize;
      if (defRPr != null) {
        final defSz = double.tryParse(defRPr.getAttribute('sz') ?? '');
        if (defSz != null && defSz > 0) defaultFontSize = (defSz / 100.0) * fontScale;
      }
      defaultFontSize ??= isTitle
          ? (38.0 * fontScale)
          : (level == 0 ? 20.0 : (level == 1 ? 18.0 : 16.0)) * fontScale;

      final runs = <SlideTextRun>[];
      for (final child in pNode.children.whereType<XmlElement>()) {
        final localName = child.name.local;
        if (localName == 'r' || localName == 'fld') {
          final tNode = child.descendants.whereType<XmlElement>().where((e) => e.name.local == 't').firstOrNull;
          if (tNode != null && tNode.innerText.isNotEmpty) {
            final rPr = child.descendants.whereType<XmlElement>().where((e) => e.name.local == 'rPr').firstOrNull;
            final isBold = rPr?.getAttribute('b') == '1' || (defRPr?.getAttribute('b') == '1');
            final isItalic = rPr?.getAttribute('i') == '1' || (defRPr?.getAttribute('i') == '1');
            final isUnderline = rPr?.getAttribute('u') == 'sng';

            double? fontSize = defaultFontSize;
            final sz = rPr?.getAttribute('sz');
            if (sz != null) {
              final szVal = double.tryParse(sz);
              if (szVal != null && szVal > 0) {
                fontSize = (szVal / 100.0) * fontScale;
              }
            }

            final color = _parseColor(rPr, themeColors) ?? _parseColor(defRPr, themeColors);

            String? fontFamily;
            final latin = rPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'latin').firstOrNull ??
                defRPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'latin').firstOrNull;
            if (latin != null) {
              final tf = latin.getAttribute('typeface');
              if (tf != null && tf.trim().isNotEmpty) {
                final cleanTf = tf.trim();
                if (cleanTf.startsWith('+mj')) {
                  fontFamily = theme.majorFont;
                } else if (cleanTf.startsWith('+mn')) {
                  fontFamily = theme.minorFont;
                } else {
                  fontFamily = cleanTf;
                }
              }
            }
            fontFamily ??= isTitle ? theme.majorFont : theme.minorFont;

            runs.add(
              SlideTextRun(
                text: tNode.innerText,
                isBold: isBold,
                isItalic: isItalic,
                isUnderline: isUnderline,
                fontSize: fontSize,
                color: color,
                fontFamily: fontFamily,
              ),
            );
          }
        } else if (localName == 't' && child.innerText.isNotEmpty) {
          runs.add(
            SlideTextRun(
              text: child.innerText,
              fontSize: defaultFontSize,
              fontFamily: isTitle ? theme.majorFont : theme.minorFont,
            ),
          );
        } else if (localName == 'br') {
          runs.add(const SlideTextRun(text: '\n'));
        }
      }

      if (runs.isEmpty) {
        final allT = pNode.descendants.whereType<XmlElement>().where((e) => e.name.local == 't');
        final rawText = allT.map((t) => t.innerText).join();
        if (rawText.isNotEmpty) {
          runs.add(SlideTextRun(
            text: rawText,
            fontSize: defaultFontSize,
            fontFamily: isTitle ? theme.majorFont : theme.minorFont,
          ));
        }
      }

      if (runs.isNotEmpty) {
        paragraphs.add(
          SlideParagraph(
            runs: runs,
            isBullet: isBullet,
            level: level,
            alignment: alignment,
          ),
        );
      }
    }

    return paragraphs;
  }

  /// Parse an embedded picture from `<p:pic>` or `<p:sp>` with `<a:blipFill>`.
  static SlideImage? _parsePicture(
    XmlElement picOrSp,
    Map<String, String> imageTargets,
    ArchiveFile? Function(String) getFile,
    double slideWidthEmu,
    double slideHeightEmu, {
    _GroupTransform? groupTransform,
  }) {
    try {
      final parsed = _parseTransform(picOrSp, slideWidthEmu, slideHeightEmu, groupTransform: groupTransform);
      final rect = parsed?.rect;
      final rot = parsed?.rotationDegrees;

      final blip = picOrSp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'blip').firstOrNull;
      final embedId = blip?.getAttribute('r:embed');
      if (embedId == null || !imageTargets.containsKey(embedId)) return null;

      final targetPath = imageTargets[embedId]!;
      final imageFile = getFile(targetPath);
      if (imageFile == null) return null;

      final bytes = Uint8List.fromList(imageFile.content as List<int>);
      final fileName = targetPath.replaceAll(r'\', '/').split('/').last.toLowerCase();
      String mimeType = 'image/png';
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) mimeType = 'image/jpeg';
      if (fileName.endsWith('.webp')) mimeType = 'image/webp';
      if (fileName.endsWith('.gif')) mimeType = 'image/gif';

      return SlideImage(
        bytes: bytes,
        mimeType: mimeType,
        name: fileName,
        rect: rect,
        rotationDegrees: rot,
      );
    } on Object catch (_) {
      return null;
    }
  }

  /// Parse group shape `<p:grpSp>` containing nested diagrams, flowcharts, or composite graphics.
  static void _parseGroupShape(
    XmlElement grpSp,
    XmlDocument? layoutDoc,
    Map<String, String> imageTargets,
    ArchiveFile? Function(String) getFile,
    double slideWidthEmu,
    double slideHeightEmu,
    _PresentationTheme theme,
    List<SlideShape> shapes,
    List<SlideImage> images,
    List<SlideVisualElement> visualElements,
    _GroupTransform? parentTransform,
  ) {
    try {
      final grpSpPr = grpSp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'grpSpPr').firstOrNull;
      final xfrm = grpSpPr?.descendants.whereType<XmlElement>().where((e) => e.name.local == 'xfrm').firstOrNull;
      if (xfrm == null) return;

      final off = xfrm.descendants.whereType<XmlElement>().where((e) => e.name.local == 'off').firstOrNull;
      final ext = xfrm.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ext').firstOrNull;
      final chOff = xfrm.descendants.whereType<XmlElement>().where((e) => e.name.local == 'chOff').firstOrNull;
      final chExt = xfrm.descendants.whereType<XmlElement>().where((e) => e.name.local == 'chExt').firstOrNull;

      double offX = double.tryParse(off?.getAttribute('x') ?? '0') ?? 0;
      double offY = double.tryParse(off?.getAttribute('y') ?? '0') ?? 0;
      double extCx = double.tryParse(ext?.getAttribute('cx') ?? '1') ?? 1;
      double extCy = double.tryParse(ext?.getAttribute('cy') ?? '1') ?? 1;
      final chOffX = double.tryParse(chOff?.getAttribute('x') ?? '0') ?? 0;
      final chOffY = double.tryParse(chOff?.getAttribute('y') ?? '0') ?? 0;
      final chExtCx = double.tryParse(chExt?.getAttribute('cx') ?? '1') ?? 1;
      final chExtCy = double.tryParse(chExt?.getAttribute('cy') ?? '1') ?? 1;

      double? rot;
      final rotAttr = xfrm.getAttribute('rot');
      if (rotAttr != null) {
        final rotVal = double.tryParse(rotAttr);
        if (rotVal != null) {
          rot = (rotVal / 60000.0) % 360.0;
        }
      }

      if (parentTransform != null) {
        final mappedOff = parentTransform.mapPoint(offX, offY);
        final mappedExt = parentTransform.mapDimensions(extCx, extCy);
        offX = mappedOff.x;
        offY = mappedOff.y;
        extCx = mappedExt.x;
        extCy = mappedExt.y;
        if (parentTransform.rot != null) {
          rot = ((rot ?? 0) + parentTransform.rot!) % 360.0;
        }
      }

      final currentGroupTransform = _GroupTransform(
        offX: offX,
        offY: offY,
        extCx: extCx,
        extCy: extCy,
        chOffX: chOffX,
        chOffY: chOffY,
        chExtCx: chExtCx,
        chExtCy: chExtCy,
        rot: rot,
      );

      int childIdx = 0;
      for (final child in grpSp.children.whereType<XmlElement>()) {
        final local = child.name.local;
        if (local == 'sp') {
          final blip = child.descendants.whereType<XmlElement>().where((e) => e.name.local == 'blip').firstOrNull;
          final embedId = blip?.getAttribute('r:embed');
          if (embedId != null && imageTargets.containsKey(embedId)) {
            final img = _parsePicture(
              child,
              imageTargets,
              getFile,
              slideWidthEmu,
              slideHeightEmu,
              groupTransform: currentGroupTransform,
            );
            if (img != null) {
              images.add(img);
              visualElements.add(SlideImageElement(image: img, rect: img.rect));
            }
          } else {
            final shape = _parseShape(
              child,
              layoutDoc,
              slideWidthEmu,
              slideHeightEmu,
              theme,
              childIdx++,
              groupTransform: currentGroupTransform,
            );
            if (shape != null) {
              shapes.add(shape);
              visualElements.add(SlideShapeElement(shape: shape, rect: shape.rect));
            }
          }
        } else if (local == 'pic') {
          final img = _parsePicture(
            child,
            imageTargets,
            getFile,
            slideWidthEmu,
            slideHeightEmu,
            groupTransform: currentGroupTransform,
          );
          if (img != null) {
            images.add(img);
            visualElements.add(SlideImageElement(image: img, rect: img.rect));
          }
        } else if (local == 'cxnSp') {
          final line = _parseConnector(
            child,
            slideWidthEmu,
            slideHeightEmu,
            theme,
            groupTransform: currentGroupTransform,
          );
          if (line != null) {
            shapes.add(line);
            visualElements.add(SlideShapeElement(shape: line, rect: line.rect));
          }
        } else if (local == 'grpSp') {
          _parseGroupShape(
            child,
            layoutDoc,
            imageTargets,
            getFile,
            slideWidthEmu,
            slideHeightEmu,
            theme,
            shapes,
            images,
            visualElements,
            currentGroupTransform,
          );
        }
      }
    } on Object catch (_) {}
  }


  /// Parse speaker notes from a `notesSlide{N}.xml` file.
  static String? _parseSpeakerNotes(ArchiveFile notesFile) {
    try {
      final doc = XmlDocument.parse(utf8.decode(notesFile.content as List<int>, allowMalformed: true));
      final buffer = StringBuffer();

      for (final sp in doc.descendants.whereType<XmlElement>().where((e) => e.name.local == 'sp')) {
        final ph = sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 'ph').firstOrNull;
        if (ph != null && ph.getAttribute('type') == 'body') {
          for (final t in sp.descendants.whereType<XmlElement>().where((e) => e.name.local == 't')) {
            if (t.innerText.isNotEmpty) {
              buffer.writeln(t.innerText);
            }
          }
        }
      }

      final text = buffer.toString().trim();
      return text.isNotEmpty ? text : null;
    } on Object catch (_) {
      return null;
    }
  }

  /// Fallback parser for legacy binary PowerPoint 97-2003 (.ppt).
  static PresentationDocument _parseLegacyPpt(_PresentationParseParams params) {
    LoggerService.info('Parsing legacy .ppt file');
    final textRuns = <String>[];
    var currentRun = <int>[];

    for (int i = 0; i < params.bytes.length; i++) {
      final b = params.bytes[i];
      if ((b >= 32 && b <= 126) || b == 9 || b == 10 || b == 13) {
        currentRun.add(b);
      } else {
        if (currentRun.length >= 4) {
          final str = String.fromCharCodes(currentRun).trim();
          if (str.length >= 4 &&
              !str.startsWith('PowerPoint') &&
              !str.startsWith('Current') &&
              !str.startsWith('Slide')) {
            textRuns.add(str);
          }
        }
        currentRun = [];
      }
    }

    final slides = <PresentationSlide>[];
    final chunkSize = math.max((textRuns.length / 10).ceil(), 3);
    for (int i = 0; i < textRuns.length; i += chunkSize) {
      final end = math.min(i + chunkSize, textRuns.length);
      final chunk = textRuns.sublist(i, end);

      final shapes = <SlideShape>[];
      for (int c = 0; c < chunk.length; c++) {
        shapes.add(
          SlideShape(
            title: c == 0,
            rect: SlideRect(
              left: 0.08,
              top: 0.15 + (c * 0.20),
              width: 0.84,
              height: 0.18,
            ),
            paragraphs: [
              SlideParagraph(
                runs: [
                  SlideTextRun(
                    text: chunk[c],
                    isBold: c == 0,
                    fontSize: c == 0 ? 24.0 : 15.0,
                    color: c == 0 ? const Color(0xFF38BDF8) : Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      }

      slides.add(
        PresentationSlide(
          slideIndex: slides.length,
          shapes: shapes,
          backgroundColor: const Color(0xFF060219),
        ),
      );
    }

    if (slides.isEmpty) {
      slides.add(
        const PresentationSlide(
          slideIndex: 0,
          shapes: [
            SlideShape(
              title: true,
              rect: SlideRect(left: 0.08, top: 0.35, width: 0.84, height: 0.25),
              paragraphs: [
                SlideParagraph(
                  runs: [
                    SlideTextRun(text: 'Presentation Document', isBold: true, fontSize: 26.0, color: Color(0xFF38BDF8)),
                  ],
                ),
              ],
            ),
          ],
          backgroundColor: Color(0xFF060219),
        ),
      );
    }

    return PresentationDocument(
      title: params.fileName,
      filePath: params.filePath,
      fileSizeBytes: params.bytes.length,
      slides: slides,
      isLegacy: true,
    );
  }
}
