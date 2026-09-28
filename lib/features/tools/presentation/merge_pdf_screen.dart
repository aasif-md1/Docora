import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/pdf_tools_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<String> _pdfPaths = [];
  final PdfToolsService _toolsService = const PdfToolsService();
  bool _isMerging = false;

  Future<void> _pickPdfs() async {
    AppMotion.subtleHaptic();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.paths.isNotEmpty) {
        final validPaths = result.paths.whereType<String>().toList();
        setState(() {
          _pdfPaths.addAll(validPaths);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick PDF files: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    AppMotion.subtleHaptic();
    setState(() => _pdfPaths.removeAt(index));
  }

  Future<void> _mergePdfs() async {
    if (_pdfPaths.length < 2) return;
    AppMotion.subtleHaptic();
    setState(() => _isMerging = true);

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${docDir.path}/Docora_Merged_$timestamp.pdf';

      final outFile = await _toolsService.mergePdfs(
        pdfPaths: _pdfPaths,
        outputPath: outPath,
      );

      setState(() => _isMerging = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDFs successfully merged!'),
            backgroundColor: AppColors.success500,
          ),
        );
        DocumentOpener.open(context, outFile.path);
      }
    } catch (e) {
      setState(() => _isMerging = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge failed: $e')),
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
        title: const Text('Merge PDFs'),
        actions: [
          if (_pdfPaths.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _pdfPaths.clear()),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pickPdfs,
                icon: const Icon(LucideIcons.file_plus, size: 18),
                label: const Text('Select PDF Documents'),
              ),
            ),
          ),
          Expanded(
            child: _pdfPaths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.merge, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text('No PDF documents selected', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Select at least 2 PDF documents to combine them into one',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _pdfPaths.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx -= 1;
                        final item = _pdfPaths.removeAt(oldIdx);
                        _pdfPaths.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final path = _pdfPaths[index];
                      final name = p.basename(path);
                      return Card(
                        key: ValueKey(path + index.toString()),
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.filePdf,
                            child: Icon(LucideIcons.file_text, color: Colors.white, size: 20),
                          ),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('File #${index + 1}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.trash, size: 18, color: AppColors.error500),
                                onPressed: () => _removeFile(index),
                              ),
                              const Icon(LucideIcons.grip_vertical, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_pdfPaths.length >= 2)
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: DocoraButton(
                label: _isMerging
                    ? 'Merging Documents...'
                    : 'Merge ${_pdfPaths.length} Documents',
                icon: LucideIcons.merge,
                isLoading: _isMerging,
                onPressed: _isMerging ? null : _mergePdfs,
              ),
            ),
        ],
      ),
    );
  }
}
