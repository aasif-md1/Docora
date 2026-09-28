import 'dart:convert';
import 'dart:io';

import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:path/path.dart' as p;

/// Service for reading plain text, markdown, and source code files with
/// automatic encoding detection and line statistics.
class TextFileService {
  const TextFileService._();

  /// Reads a file from disk, detecting encoding (UTF-8, UTF-16, Latin-1) and language.
  static Future<TextDocument> readFile(String filePath) async {
    var resolvedPath = filePath;
    if (resolvedPath.startsWith('file://')) {
      try {
        resolvedPath = Uri.parse(resolvedPath).toFilePath();
      } catch (_) {
        resolvedPath = resolvedPath.replaceFirst('file://', '');
      }
    }
    if (resolvedPath.contains('%')) {
      try {
        resolvedPath = Uri.decodeFull(resolvedPath);
      } catch (_) {}
    }

    final file = File(resolvedPath);
    if (!file.existsSync()) {
      throw FileSystemException('File does not exist', resolvedPath);
    }

    final bytes = await file.readAsBytes();
    final fileName = p.basename(filePath);
    final size = bytes.length;

    final decoded = _decodeBytes(bytes);
    final content = decoded.text;
    final encodingName = decoded.encodingName;

    final lines = _splitLines(content);
    final langInfo = LanguageDetector.detect(filePath);

    return TextDocument(
      filePath: filePath,
      fileName: fileName,
      content: content,
      fileSizeBytes: size,
      encodingName: encodingName,
      highlightLanguage: langInfo.highlightLang,
      languageLabel: langInfo.label,
      isCode: langInfo.isCode,
      isMarkdown: langInfo.isMarkdown,
      lines: lines,
    );
  }

  /// Decode byte stream into text by checking BOM markers and fallbacks.
  static ({String text, String encodingName}) _decodeBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return (text: '', encodingName: 'UTF-8');
    }

    // 1. Check for UTF-8 BOM (0xEF, 0xBB, 0xBF)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return (
        text: utf8.decode(bytes.sublist(3), allowMalformed: true),
        encodingName: 'UTF-8 (BOM)',
      );
    }

    // 2. Check for UTF-16 LE BOM (0xFF, 0xFE)
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      final buffer = StringBuffer();
      for (int i = 2; i < bytes.length - 1; i += 2) {
        final codeUnit = bytes[i] | (bytes[i + 1] << 8);
        buffer.writeCharCode(codeUnit);
      }
      return (text: buffer.toString(), encodingName: 'UTF-16 LE');
    }

    // 3. Check for UTF-16 BE BOM (0xFE, 0xFF)
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final buffer = StringBuffer();
      for (int i = 2; i < bytes.length - 1; i += 2) {
        final codeUnit = (bytes[i] << 8) | bytes[i + 1];
        buffer.writeCharCode(codeUnit);
      }
      return (text: buffer.toString(), encodingName: 'UTF-16 BE');
    }

    // 4. Attempt standard UTF-8 decode
    try {
      final text = const Utf8Decoder().convert(bytes);
      return (text: text, encodingName: 'UTF-8');
    } on FormatException {
      // 5. Fallback to ISO-8859-1 (Latin-1) which never fails on 8-bit bytes
      final text = latin1.decode(bytes);
      return (text: text, encodingName: 'ISO-8859-1 (Latin-1)');
    }
  }

  /// Splits content into lines normalizing CRLF and LF.
  static List<String> _splitLines(String content) {
    if (content.isEmpty) return const [''];
    return content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  }
}
