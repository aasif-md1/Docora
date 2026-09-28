import 'dart:io';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/pdf_tools_service.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum CompressionLevel {
  low('Low Compression', 'Highest quality, minimal size reduction (~20%)'),
  recommended('Recommended', 'Optimal balance of sharpness and file size (~50%)'),
  extreme('Maximum Compression', 'Smallest file size, ideal for email & WhatsApp (~75%)');

  const CompressionLevel(this.label, this.subtitle);
  final String label;
  final String subtitle;
}

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  String? _selectedPdfPath;
  int _originalSizeBytes = 0;
  int _compressedSizeBytes = 0;
  String? _compressedOutputPath;
  CompressionLevel _level = CompressionLevel.recommended;
  final PdfToolsService _toolsService = const PdfToolsService();
  bool _isCompressing = false;

  Future<void> _pickPdf() async {
    AppMotion.subtleHaptic();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final size = await file.length();
        setState(() {
          _selectedPdfPath = path;
          _originalSizeBytes = size;
          _compressedOutputPath = null;
          _compressedSizeBytes = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick PDF: $e')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _compressPdf() async {
    if (_selectedPdfPath == null) return;
    AppMotion.subtleHaptic();
    setState(() => _isCompressing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final baseName = p.basenameWithoutExtension(_selectedPdfPath!);
      final outPath = p.join(
        tempDir.path,
        '${baseName}_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      final outFile = await _toolsService.compressPdf(
        inputPath: _selectedPdfPath!,
        outputPath: outPath,
      );

      final newSize = await outFile.length();

      setState(() {
        _compressedOutputPath = outFile.path;
        _compressedSizeBytes = newSize;
        _isCompressing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF compressed successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compression failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compress PDF'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pick Card or Selected File Card
            if (_selectedPdfPath == null)
              InkWell(
                onTap: _pickPdf,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.file_down,
                          size: 36,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a PDF Document',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reduce file size while preserving readability',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.file_text,
                          color: Color(0xFFEF4444),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.basename(_selectedPdfPath!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Original Size: ${_formatBytes(_originalSizeBytes)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.refresh_cw, size: 20),
                        tooltip: 'Choose another file',
                        onPressed: _pickPdf,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Compression Level',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...CompressionLevel.values.map((lvl) {
                final isSelected = _level == lvl;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      AppMotion.subtleHaptic();
                      setState(() => _level = lvl);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withAlpha(25)
                            : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LucideIcons.circle_dot
                                : LucideIcons.circle,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lvl.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lvl.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Success Result Card
            if (_compressedOutputPath != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.circle_check, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text(
                          'Compression Complete!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Before',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatBytes(_originalSizeBytes),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(LucideIcons.arrow_right, size: 20),
                        Column(
                          children: [
                            Text(
                              'After',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatBytes(_compressedSizeBytes),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: DocoraButton(
                        label: 'Open Compressed PDF',
                        icon: LucideIcons.external_link,
                        onPressed: () {
                          final outPath = _compressedOutputPath;
                          if (outPath != null) DocumentOpener.open(outPath);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (_selectedPdfPath != null && _compressedOutputPath == null)
              DocoraButton(
                label: _isCompressing ? 'Compressing PDF...' : 'Compress PDF',
                icon: LucideIcons.sparkles,
                isLoading: _isCompressing,
                onPressed: _isCompressing ? null : _compressPdf,
              ),
          ],
        ),
      ),
    );
  }
}
