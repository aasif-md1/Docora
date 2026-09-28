import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/features/viewer/domain/models/epub_models.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Parameters for background EPUB parsing isolate.
class _EpubParseParams {
  const _EpubParseParams({
    required this.bytes,
    required this.filePath,
    required this.fileName,
  });

  final Uint8List bytes;
  final String filePath;
  final String fileName;
}

/// Offline parser for EPUB e-books (.epub) based on the IDPF EPUB standard.
class EpubParserService {
  const EpubParserService._();

  /// Parse an EPUB file asynchronously using a background isolate.
  static Future<EpubDocument> parseFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('EPUB file does not exist', filePath);
    }

    final bytes = await file.readAsBytes();
    final fileName = p.basename(filePath);

    final params = _EpubParseParams(
      bytes: bytes,
      filePath: filePath,
      fileName: fileName,
    );

    return compute(_parseEpubIsolate, params);
  }

  /// Parse EPUB ZIP archive inside a background isolate.
  static EpubDocument _parseEpubIsolate(_EpubParseParams params) {
    try {
      final archive = ZipDecoder().decodeBytes(params.bytes);
      final filesMap = <String, ArchiveFile>{};
      for (final file in archive.files) {
        // Normalize path separators to forward slash
        final normalized = file.name.replaceAll(r'\', '/');
        filesMap[normalized] = file;
      }

      // Step 1: Find OPF package file from META-INF/container.xml
      final opfPath = _findOpfPath(filesMap);
      if (opfPath == null || !filesMap.containsKey(opfPath)) {
        return _fallbackParseWithoutOpf(params, filesMap);
      }

      final opfFile = filesMap[opfPath]!;
      final opfContent = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
      final opfXml = XmlDocument.parse(opfContent);

      final opfDir = p.dirname(opfPath).replaceAll(r'\', '/');
      final baseDir = opfDir == '.' ? '' : '$opfDir/';

      // Step 2: Parse metadata
      final metadataElement = opfXml.findAllElements('metadata').firstOrNull;
      var title = params.fileName.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');
      String? author;
      String? description;
      String? publisher;
      String? coverItemId;

      if (metadataElement != null) {
        final titleElem = metadataElement.findElements('dc:title').firstOrNull ??
            metadataElement.findElements('title').firstOrNull;
        if (titleElem != null && titleElem.innerText.trim().isNotEmpty) {
          title = titleElem.innerText.trim();
        }

        final creatorElem = metadataElement.findElements('dc:creator').firstOrNull ??
            metadataElement.findElements('creator').firstOrNull;
        if (creatorElem != null && creatorElem.innerText.trim().isNotEmpty) {
          author = creatorElem.innerText.trim();
        }

        final descElem = metadataElement.findElements('dc:description').firstOrNull ??
            metadataElement.findElements('description').firstOrNull;
        if (descElem != null && descElem.innerText.trim().isNotEmpty) {
          description = descElem.innerText.trim();
        }

        final pubElem = metadataElement.findElements('dc:publisher').firstOrNull ??
            metadataElement.findElements('publisher').firstOrNull;
        if (pubElem != null && pubElem.innerText.trim().isNotEmpty) {
          publisher = pubElem.innerText.trim();
        }

        // Search for cover meta tag: <meta name="cover" content="item_id"/>
        for (final meta in metadataElement.findElements('meta')) {
          if (meta.getAttribute('name')?.toLowerCase() == 'cover') {
            coverItemId = meta.getAttribute('content');
            break;
          }
        }
      }

      // Step 3: Parse manifest items
      final manifestMap = <String, _ManifestItem>{};
      String? ncxPath;
      String? navPath;
      String? coverItemHref;

      final manifestElem = opfXml.findAllElements('manifest').firstOrNull;
      if (manifestElem != null) {
        for (final item in manifestElem.findElements('item')) {
          final id = item.getAttribute('id') ?? '';
          final href = item.getAttribute('href') ?? '';
          final mediaType = item.getAttribute('media-type') ?? '';
          final properties = item.getAttribute('properties') ?? '';

          if (id.isNotEmpty && href.isNotEmpty) {
            manifestMap[id] = _ManifestItem(
              id: id,
              href: href,
              mediaType: mediaType,
              properties: properties,
            );

            if (mediaType == 'application/x-dtbncx+xml' || href.endsWith('.ncx')) {
              ncxPath = _resolvePath(baseDir, href);
            }
            if (properties.contains('nav')) {
              navPath = _resolvePath(baseDir, href);
            }
            if (properties.contains('cover-image') || id.toLowerCase().contains('cover')) {
              coverItemHref = _resolvePath(baseDir, href);
            }
          }
        }
      }

      // If coverItemId was found from metadata, prioritize its href
      if (coverItemId != null && manifestMap.containsKey(coverItemId)) {
        coverItemHref = _resolvePath(baseDir, manifestMap[coverItemId]!.href);
      }

      // Load cover image bytes if available
      Uint8List? coverBytes;
      if (coverItemHref != null && filesMap.containsKey(coverItemHref)) {
        final coverFile = filesMap[coverItemHref]!;
        coverBytes = Uint8List.fromList(coverFile.content as List<int>);
      }

      // Step 4: Parse spine in linear reading order
      final spineElem = opfXml.findAllElements('spine').firstOrNull;
      final chapters = <EpubChapter>[];

      if (spineElem != null) {
        int chapterIndex = 0;
        for (final itemRef in spineElem.findElements('itemref')) {
          final idref = itemRef.getAttribute('idref') ?? '';
          if (idref.isNotEmpty && manifestMap.containsKey(idref)) {
            final item = manifestMap[idref]!;
            final fullHref = _resolvePath(baseDir, item.href);

            if (filesMap.containsKey(fullHref)) {
              final chapterFile = filesMap[fullHref]!;
              final html = utf8.decode(chapterFile.content as List<int>, allowMalformed: true);
              final chTitle = _extractChapterTitle(html, defaultTitle: 'Chapter ${chapterIndex + 1}');

              chapters.add(
                EpubChapter(
                  id: idref,
                  title: chTitle,
                  href: fullHref,
                  htmlContent: html,
                  chapterIndex: chapterIndex,
                ),
              );
              chapterIndex++;
            }
          }
        }
      }

      // If spine produced no chapters, fallback to reading all HTML files
      if (chapters.isEmpty) {
        return _fallbackParseWithoutOpf(params, filesMap, title: title, author: author, coverBytes: coverBytes);
      }

      // Step 5: Parse Table of Contents (NCX or EPUB 3 Nav)
      final tocEntries = _parseToc(filesMap, ncxPath, navPath, chapters);

      return EpubDocument(
        title: title,
        filePath: params.filePath,
        fileSizeBytes: params.bytes.length,
        chapters: chapters,
        toc: tocEntries,
        author: author,
        description: description,
        publisher: publisher,
        coverImageBytes: coverBytes,
      );
    } on Object catch (e, stack) {
      LoggerService.warning('Failed to parse EPUB archive: $e', error: e, stackTrace: stack);
      return EpubDocument.empty(
        title: params.fileName,
        filePath: params.filePath,
      );
    }
  }

  /// Locates the path to the root OPF file from META-INF/container.xml.
  static String? _findOpfPath(Map<String, ArchiveFile> files) {
    const containerKey = 'META-INF/container.xml';
    // Case-insensitive lookup for container.xml
    ArchiveFile? containerFile;
    for (final key in files.keys) {
      if (key.toLowerCase() == containerKey.toLowerCase()) {
        containerFile = files[key];
        break;
      }
    }

    if (containerFile != null) {
      try {
        final xmlStr = utf8.decode(containerFile.content as List<int>, allowMalformed: true);
        final doc = XmlDocument.parse(xmlStr);
        final rootfile = doc.findAllElements('rootfile').firstOrNull;
        if (rootfile != null) {
          final fullPath = rootfile.getAttribute('full-path');
          if (fullPath != null && fullPath.isNotEmpty) {
            return fullPath.replaceAll(r'\', '/');
          }
        }
      } on Object catch (_) {}
    }

    // Fallback search for any .opf file in archive
    for (final key in files.keys) {
      if (key.toLowerCase().endsWith('.opf')) {
        return key;
      }
    }

    return null;
  }

  /// Resolve relative paths against the OPF package base directory.
  static String _resolvePath(String baseDir, String relativeHref) {
    final cleanHref = relativeHref.split('#').first;
    if (baseDir.isEmpty) return cleanHref;
    return p.normalize('$baseDir$cleanHref').replaceAll(r'\', '/');
  }

  /// Extracts chapter title from HTML `<title>`, `<h1>`, or `<h2>` tag.
  static String _extractChapterTitle(String html, {required String defaultTitle}) {
    final titleMatch = RegExp('<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
    if (titleMatch != null) {
      final t = titleMatch.group(1)?.replaceAll(RegExp('<[^>]*>'), '').trim();
      if (t != null && t.isNotEmpty) return t;
    }

    final h1Match = RegExp('<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true).firstMatch(html);
    if (h1Match != null) {
      final h = h1Match.group(1)?.replaceAll(RegExp('<[^>]*>'), '').trim();
      if (h != null && h.isNotEmpty) return h;
    }

    final h2Match = RegExp('<h2[^>]*>(.*?)</h2>', caseSensitive: false, dotAll: true).firstMatch(html);
    if (h2Match != null) {
      final h2 = h2Match.group(1)?.replaceAll(RegExp('<[^>]*>'), '').trim();
      if (h2 != null && h2.isNotEmpty) return h2;
    }

    return defaultTitle;
  }

  /// Parses Table of Contents from NCX file or EPUB 3 Nav XHTML.
  static List<EpubTocEntry> _parseToc(
    Map<String, ArchiveFile> files,
    String? ncxPath,
    String? navPath,
    List<EpubChapter> chapters,
  ) {
    if (ncxPath != null && files.containsKey(ncxPath)) {
      try {
        final ncxXmlStr = utf8.decode(files[ncxPath]!.content as List<int>, allowMalformed: true);
        final doc = XmlDocument.parse(ncxXmlStr);
        final navMap = doc.findAllElements('navMap').firstOrNull;
        if (navMap != null) {
          final entries = <EpubTocEntry>[];
          for (final navPoint in navMap.findElements('navPoint')) {
            final entry = _parseNavPoint(navPoint, chapters);
            if (entry != null) entries.add(entry);
          }
          if (entries.isNotEmpty) return entries;
        }
      } on Object catch (_) {}
    }

    // Default TOC generated from chapters if no TOC file found
    return [
      for (int i = 0; i < chapters.length; i++)
        EpubTocEntry(
          title: chapters[i].title,
          href: chapters[i].href,
          targetChapterIndex: i,
        ),
    ];
  }

  static EpubTocEntry? _parseNavPoint(XmlElement navPoint, List<EpubChapter> chapters) {
    final textElem = navPoint.findAllElements('text').firstOrNull;
    final contentElem = navPoint.findElements('content').firstOrNull;
    final title = textElem?.innerText.trim() ?? 'Section';
    final src = contentElem?.getAttribute('src') ?? '';

    final cleanSrc = src.split('#').first;
    int targetIdx = 0;
    for (int i = 0; i < chapters.length; i++) {
      if (chapters[i].href.endsWith(cleanSrc) || cleanSrc.endsWith(p.basename(chapters[i].href))) {
        targetIdx = i;
        break;
      }
    }

    final children = <EpubTocEntry>[];
    for (final child in navPoint.findElements('navPoint')) {
      final childEntry = _parseNavPoint(child, chapters);
      if (childEntry != null) children.add(childEntry);
    }

    return EpubTocEntry(
      title: title,
      href: src,
      targetChapterIndex: targetIdx,
      children: children,
    );
  }

  /// Fallback parsing if container.xml or OPF is missing or corrupt.
  static EpubDocument _fallbackParseWithoutOpf(
    _EpubParseParams params,
    Map<String, ArchiveFile> files, {
    String? title,
    String? author,
    Uint8List? coverBytes,
  }) {
    final bookTitle = title ?? params.fileName.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');
    final htmlFiles = files.keys
        .where((k) => k.endsWith('.html') || k.endsWith('.xhtml') || k.endsWith('.htm'))
        .toList()
      ..sort();

    final chapters = <EpubChapter>[];
    for (int i = 0; i < htmlFiles.length; i++) {
      final key = htmlFiles[i];
      final content = utf8.decode(files[key]!.content as List<int>, allowMalformed: true);
      final chTitle = _extractChapterTitle(content, defaultTitle: 'Chapter ${i + 1}');

      chapters.add(
        EpubChapter(
          id: 'ch_$i',
          title: chTitle,
          href: key,
          htmlContent: content,
          chapterIndex: i,
        ),
      );
    }

    final toc = [
      for (int i = 0; i < chapters.length; i++)
        EpubTocEntry(
          title: chapters[i].title,
          href: chapters[i].href,
          targetChapterIndex: i,
        ),
    ];

    return EpubDocument(
      title: bookTitle,
      filePath: params.filePath,
      fileSizeBytes: params.bytes.length,
      chapters: chapters,
      toc: toc,
      author: author,
      coverImageBytes: coverBytes,
    );
  }
}

class _ManifestItem {
  const _ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.properties,
  });

  final String id;
  final String href;
  final String mediaType;
  final String properties;
}
