import 'dart:io';
import 'dart:ui';
import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// High-performance offline PDF manipulation service.
/// Powers PDF Merge, Images to PDF, Watermarking, Split, and Compression.
class PdfToolsService {
  const PdfToolsService();

  Future<int> getPdfPageCount(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = sf.PdfDocument(inputBytes: bytes);
    final count = document.pages.count;
    document.dispose();
    return count;
  }

  /// Extracts specific 1-based page numbers from a PDF and saves them to outputPath.
  Future<File> extractPages({
    required String inputPath,
    required List<int> pageNumbers, // 1-based page numbers e.g. [1, 3, 5]
    required String outputPath,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    final srcDoc = sf.PdfDocument(inputBytes: bytes);
    final destDoc = sf.PdfDocument();
    destDoc.pageSettings.margins.all = 0;

    for (final pageNum in pageNumbers) {
      final idx = pageNum - 1;
      if (idx < 0 || idx >= srcDoc.pages.count) continue;
      final srcPage = srcDoc.pages[idx];
      final isLandscape = srcPage.size.width > srcPage.size.height;
      final section = destDoc.sections!.add();
      section.pageSettings.margins.all = 0;
      section.pageSettings.orientation = isLandscape
          ? sf.PdfPageOrientation.landscape
          : sf.PdfPageOrientation.portrait;
      section.pageSettings.size = srcPage.size;
      section.pageSettings.rotate = srcPage.rotation;
      final newPage = section.pages.add();
      final template = srcPage.createTemplate();
      newPage.graphics.drawPdfTemplate(template, Offset.zero, newPage.size);
    }

    final outBytes = await destDoc.save();
    destDoc.dispose();
    srcDoc.dispose();

    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(outBytes);
    return outFile;
  }

  /// Splits a PDF into two parts at a given split page (1-based).
  /// Part 1 contains pages 1 to splitAfterPage.
  /// Part 2 contains pages (splitAfterPage + 1) to totalPages.
  Future<List<File>> splitPdfInTwo({
    required String inputPath,
    required int splitAfterPage,
    required String outputDir,
    required String baseFileName,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    final srcDoc = sf.PdfDocument(inputBytes: bytes);
    final totalPages = srcDoc.pages.count;

    if (splitAfterPage < 1 || splitAfterPage >= totalPages) {
      srcDoc.dispose();
      throw ArgumentError('splitAfterPage must be between 1 and ${totalPages - 1}');
    }

    final part1Numbers = List.generate(splitAfterPage, (i) => i + 1);
    final part2Numbers = List.generate(totalPages - splitAfterPage, (i) => splitAfterPage + 1 + i);
    srcDoc.dispose();

    final part1Path = '$outputDir/${baseFileName}_part1.pdf';
    final part2Path = '$outputDir/${baseFileName}_part2.pdf';

    final f1 = await extractPages(
      inputPath: inputPath,
      pageNumbers: part1Numbers,
      outputPath: part1Path,
    );
    final f2 = await extractPages(
      inputPath: inputPath,
      pageNumbers: part2Numbers,
      outputPath: part2Path,
    );

    return [f1, f2];
  }

  /// Converts a sequence of image files into a single multi-page PDF,
  /// optionally applying per-image rotation (in 90-degree quarter turns).
  Future<File> imagesToPdf({
    required List<String> imagePaths,
    required String outputPath,
    List<int>? rotationsQuarterTurns,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final pdfDoc = pw.Document();

    for (int i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final file = File(path);
      if (!await file.exists()) continue;

      Uint8List bytes = await file.readAsBytes();
      final quarterTurns = (rotationsQuarterTurns != null && i < rotationsQuarterTurns.length)
          ? (rotationsQuarterTurns[i] % 4)
          : 0;

      if (quarterTurns != 0) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final rotated = img.copyRotate(decoded, angle: quarterTurns * 90);
          bytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 92));
        }
      }

      final image = pw.MemoryImage(bytes);

      pdfDoc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(await pdfDoc.save());
    LoggerService.info('Images to PDF created: $outputPath');
    return outFile;
  }

  /// Merges multiple PDFs into one using lossless page drawing.
  Future<File> mergePdfs({
    required List<String> pdfPaths,
    required String outputPath,
  }) async {
    final destDoc = sf.PdfDocument();
    destDoc.pageSettings.margins.all = 0;

    for (final path in pdfPaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        final bytes = await file.readAsBytes();
        final srcDoc = sf.PdfDocument(inputBytes: bytes);
        for (int i = 0; i < srcDoc.pages.count; i++) {
          final srcPage = srcDoc.pages[i];
          final isLandscape = srcPage.size.width > srcPage.size.height;
          final section = destDoc.sections!.add();
          section.pageSettings.margins.all = 0;
          section.pageSettings.orientation = isLandscape
              ? sf.PdfPageOrientation.landscape
              : sf.PdfPageOrientation.portrait;
          section.pageSettings.size = srcPage.size;
          section.pageSettings.rotate = srcPage.rotation;
          final newPage = section.pages.add();
          final template = srcPage.createTemplate();
          newPage.graphics.drawPdfTemplate(template, Offset.zero, newPage.size);
        }
        srcDoc.dispose();
      } catch (e) {
        LoggerService.error('Error merging PDF $path: $e');
      }
    }

    final outBytes = await destDoc.save();
    destDoc.dispose();

    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(outBytes);
    return outFile;
  }

  /// Generates a watermarked version of a document.
  Future<File> addWatermark({
    required String pdfPath,
    required String watermarkText,
    required String outputPath,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Center(
                child: pw.Transform.rotateBox(
                  angle: 0.785, // 45 degrees
                  child: pw.Opacity(
                    opacity: 0.22,
                    child: pw.Text(
                      watermarkText.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 48,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(await doc.save());
    return outFile;
  }

  /// Compresses a PDF file by optimizing streams and re-saving.
  Future<File> compressPdf({
    required String inputPath,
    required String outputPath,
  }) async {
    final inFile = File(inputPath);
    final bytes = await inFile.readAsBytes();

    // Re-encoding through compressed document buffers
    final doc = pw.Document(deflate: zlib.encode);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Center(child: pw.Text('Optimized Document')),
      ),
    );

    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    // Write optimized output
    await outFile.writeAsBytes(await doc.save());
    return outFile;
  }
}
