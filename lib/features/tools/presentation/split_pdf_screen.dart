import 'dart:io';

import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/pdf_tools_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum SplitMode {
  splitInTwo,
  extractPages,
}

/// Offline PDF Split & Page Extraction tool.
class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({this.initialFilePath, super.key});

  final String? initialFilePath;

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  final PdfToolsService _toolsService = const PdfToolsService();
  final TextEditingController _rangeController = TextEditingController();

  String? _filePath;
  int _totalPages = 0;
  int _fileSizeBytes = 0;
  bool _isLoadingPdf = false;
  bool _isProcessing = false;

  SplitMode _mode = SplitMode.splitInTwo;
  int _splitAfterPage = 1;
  final Set<int> _selectedPages = <int>{};

  List<File> _generatedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
      _loadPdf(widget.initialFilePath!);
    }
  }

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    AppMotion.subtleHaptic();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        await _loadPdf(result.files.single.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: $e')),
        );
      }
    }
  }

  Future<void> _loadPdf(String path) async {
    setState(() {
      _isLoadingPdf = true;
      _generatedFiles = [];
    });

    try {
      final file = File(path);
      final size = await file.length();
      final count = await _toolsService.getPdfPageCount(path);

      if (mounted) {
        setState(() {
          _filePath = path;
          _fileSizeBytes = size;
          _totalPages = count;
          _splitAfterPage = (count / 2).ceil().clamp(1, count > 1 ? count - 1 : 1);
          _selectedPages.clear();
          if (count > 0) {
            _selectedPages.add(1);
          }
          _rangeController.text = _selectedPages.join(', ');
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  void _onRangeTextChanged(String value) {
    final parsed = _parsePageRange(value, _totalPages);
    setState(() {
      _selectedPages.clear();
      _selectedPages.addAll(parsed);
    });
  }

  Set<int> _parsePageRange(String input, int maxPages) {
    final results = <int>{};
    final parts = input.split(',');
    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      if (part.contains('-')) {
        final rangeParts = part.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim());
          final end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null) {
            final minP = start.clamp(1, maxPages);
            final maxP = end.clamp(1, maxPages);
            for (int i = minP; i <= maxP; i++) {
              results.add(i);
            }
          }
        }
      } else {
        final page = int.tryParse(part);
        if (page != null && page >= 1 && page <= maxPages) {
          results.add(page);
        }
      }
    }
    return results;
  }

  void _togglePageSelection(int page) {
    AppMotion.subtleHaptic();
    setState(() {
      if (_selectedPages.contains(page)) {
        _selectedPages.remove(page);
      } else {
        _selectedPages.add(page);
      }
      final sorted = _selectedPages.toList()..sort();
      _rangeController.text = sorted.join(', ');
    });
  }

  Future<void> _executeSplitOrExtract() async {
    if (_filePath == null) return;
    AppMotion.mediumHaptic();

    setState(() {
      _isProcessing = true;
      _generatedFiles = [];
    });

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final baseName = p.basenameWithoutExtension(_filePath!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (_mode == SplitMode.splitInTwo) {
        if (_totalPages < 2) {
          throw Exception('Document must have at least 2 pages to split in 2 parts.');
        }

        final files = await _toolsService.splitPdfInTwo(
          inputPath: _filePath!,
          splitAfterPage: _splitAfterPage,
          outputDir: docDir.path,
          baseFileName: '${baseName}_$timestamp',
        );

        if (mounted) {
          setState(() {
            _generatedFiles = files;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF split into 2 files successfully!'),
              backgroundColor: AppColors.success500,
            ),
          );
        }
      } else {
        // Extract selected pages
        if (_selectedPages.isEmpty) {
          throw Exception('Please select at least 1 page to extract.');
        }

        final sortedPages = _selectedPages.toList()..sort();
        final outPath = '${docDir.path}/${baseName}_extracted_$timestamp.pdf';

        final file = await _toolsService.extractPages(
          inputPath: _filePath!,
          pageNumbers: sortedPages,
          outputPath: outPath,
        );

        if (mounted) {
          setState(() {
            _generatedFiles = [file];
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${sortedPages.length} page(s) extracted successfully!'),
              backgroundColor: AppColors.success500,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Split failed: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Split PDF'),
        centerTitle: false,
        actions: [
          if (_filePath != null)
            TextButton.icon(
              onPressed: _pickPdf,
              icon: const Icon(LucideIcons.folder_open, size: 18),
              label: const Text('Change'),
            ),
        ],
      ),
      body: _isLoadingPdf
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_filePath == null) ...[
                    _buildPickPlaceholder(colorScheme),
                  ] else ...[
                    _buildFileInfoCard(colorScheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildModeSelector(colorScheme),
                    const SizedBox(height: AppSpacing.lg),
                    if (_mode == SplitMode.splitInTwo)
                      _buildSplitInTwoControls(colorScheme)
                    else
                      _buildExtractPagesControls(colorScheme),
                    const SizedBox(height: AppSpacing.xl),
                    DocoraButton(
                      label: _isProcessing
                          ? 'Processing PDF...'
                          : (_mode == SplitMode.splitInTwo
                              ? 'Split into 2 Files'
                              : 'Extract ${_selectedPages.length} Page(s)'),
                      icon: LucideIcons.scissors,
                      size: DocoraButtonSize.large,
                      isFullWidth: true,
                      isLoading: _isProcessing,
                      onPressed: (_isProcessing ||
                              (_mode == SplitMode.splitInTwo && _totalPages < 2) ||
                              (_mode == SplitMode.extractPages && _selectedPages.isEmpty))
                          ? null
                          : _executeSplitOrExtract,
                    ),
                    if (_generatedFiles.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildResultsSection(colorScheme),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPickPlaceholder(ColorScheme colorScheme) {
    return InkWell(
      onTap: _pickPdf,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.file_text,
                size: 48,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Select a PDF to Split',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Split document in 2 parts or extract specific pages',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            DocoraButton(
              label: 'Browse PDF',
              icon: LucideIcons.folder_open,
              onPressed: _pickPdf,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.shield_check,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '100% Offline & Private on Device',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoCard(ColorScheme colorScheme) {
    final fileName = p.basename(_filePath!);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              LucideIcons.file_text,
              color: Color(0xFFEF4444),
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _formatFileSize(_fileSizeBytes),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_totalPages ${_totalPages == 1 ? 'Page' : 'Pages'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              title: 'Split into 2 Parts',
              icon: LucideIcons.scissors,
              isSelected: _mode == SplitMode.splitInTwo,
              onTap: () {
                AppMotion.subtleHaptic();
                setState(() => _mode = SplitMode.splitInTwo);
              },
            ),
          ),
          Expanded(
            child: _ModeTab(
              title: 'Extract Page(s)',
              icon: LucideIcons.copy,
              isSelected: _mode == SplitMode.extractPages,
              onTap: () {
                AppMotion.subtleHaptic();
                setState(() => _mode = SplitMode.extractPages);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitInTwoControls(ColorScheme colorScheme) {
    if (_totalPages < 2) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.triangle_alert, color: Color(0xFFF59E0B)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This PDF only has 1 page. Switch to "Extract Page(s)" or choose a multi-page PDF.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Split Point:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              'After Page $_splitAfterPage of $_totalPages',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
          ),
          child: Slider(
            value: _splitAfterPage.toDouble(),
            min: 1,
            max: (_totalPages - 1).toDouble(),
            divisions: (_totalPages - 1) > 0 ? (_totalPages - 1) : 1,
            label: 'After Page $_splitAfterPage',
            onChanged: (val) {
              AppMotion.subtleHaptic();
              setState(() => _splitAfterPage = val.round());
            },
          ),
        ),
        const SizedBox(height: 12),
        // Live visual breakdown of the two resulting files
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.file_text, size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 6),
                        Text(
                          'Part 1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pages 1 - $_splitAfterPage',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_splitAfterPage ${_splitAfterPage == 1 ? 'page' : 'pages'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.file_text, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Part 2',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pages ${_splitAfterPage + 1} - $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_totalPages - _splitAfterPage} ${(_totalPages - _splitAfterPage) == 1 ? 'page' : 'pages'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExtractPagesControls(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Pages to Extract:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '${_selectedPages.length} selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Quick Presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ActionChip(
                label: const Text('Page 1 Only'),
                avatar: const Icon(LucideIcons.file, size: 14),
                onPressed: () {
                  AppMotion.subtleHaptic();
                  setState(() {
                    _selectedPages.clear();
                    _selectedPages.add(1);
                    _rangeController.text = '1';
                  });
                },
              ),
              const SizedBox(width: 8),
              if (_totalPages > 1) ...[
                ActionChip(
                  label: Text('Last Page ($_totalPages)'),
                  avatar: const Icon(LucideIcons.file_text, size: 14),
                  onPressed: () {
                    AppMotion.subtleHaptic();
                    setState(() {
                      _selectedPages.clear();
                      _selectedPages.add(_totalPages);
                      _rangeController.text = '$_totalPages';
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
              ActionChip(
                label: const Text('All Pages'),
                avatar: const Icon(LucideIcons.check_check, size: 14),
                onPressed: () {
                  AppMotion.subtleHaptic();
                  setState(() {
                    _selectedPages.clear();
                    for (int i = 1; i <= _totalPages; i++) {
                      _selectedPages.add(i);
                    }
                    _rangeController.text = '1-$_totalPages';
                  });
                },
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(LucideIcons.x, size: 14),
                onPressed: () {
                  AppMotion.subtleHaptic();
                  setState(() {
                    _selectedPages.clear();
                    _rangeController.clear();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Manual range input
        TextField(
          controller: _rangeController,
          decoration: InputDecoration(
            labelText: 'Page numbers or range',
            hintText: 'e.g. 1, 3-5, 8',
            prefixIcon: const Icon(LucideIcons.file_digit, size: 20),
            suffixIcon: _rangeController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () {
                      _rangeController.clear();
                      setState(() => _selectedPages.clear());
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onChanged: _onRangeTextChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        // Interactive Page Chips Grid
        const Text(
          'Tap page cards to toggle:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_totalPages, (index) {
            final pageNum = index + 1;
            final isSelected = _selectedPages.contains(pageNum);
            return FilterChip(
              label: Text('Page $pageNum'),
              selected: isSelected,
              showCheckmark: true,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              onSelected: (_) => _togglePageSelection(pageNum),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildResultsSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success500.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success500.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.circle_check, color: AppColors.success500, size: 22),
              const SizedBox(width: 8),
              Text(
                'Created ${_generatedFiles.length} ${_generatedFiles.length == 1 ? 'File' : 'Files'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ..._generatedFiles.map((file) {
            final name = p.basename(file.path);
            final size = file.existsSync() ? _formatFileSize(file.lengthSync()) : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.file_text, size: 20, color: Color(0xFFEF4444)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (size.isNotEmpty)
                          Text(
                            size,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open PDF',
                    icon: const Icon(LucideIcons.external_link, size: 18),
                    onPressed: () {
                      AppMotion.subtleHaptic();
                      DocumentOpener.open(context, file.path);
                    },
                  ),
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(LucideIcons.share_2, size: 18),
                    onPressed: () {
                      AppMotion.subtleHaptic();
                      Share.shareXFiles([XFile(file.path)], text: name);
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
