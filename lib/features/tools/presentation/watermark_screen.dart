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

class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  String? _selectedPdfPath;
  final TextEditingController _watermarkController =
      TextEditingController(text: 'CONFIDENTIAL');
  final PdfToolsService _toolsService = const PdfToolsService();
  bool _isProcessing = false;

  final List<String> _presets = [
    'CONFIDENTIAL',
    'DRAFT',
    'SAMPLE',
    'DO NOT COPY',
    'INTERNAL USE',
    'APPROVED',
  ];

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    AppMotion.subtleHaptic();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdfPath = result.files.single.path;
      });
    }
  }

  Future<void> _applyWatermark() async {
    if (_selectedPdfPath == null || _watermarkController.text.trim().isEmpty) {
      return;
    }

    AppMotion.subtleHaptic();
    setState(() => _isProcessing = true);

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${docDir.path}/Docora_Watermarked_$timestamp.pdf';

      final outFile = await _toolsService.addWatermark(
        pdfPath: _selectedPdfPath!,
        watermarkText: _watermarkController.text.trim(),
        outputPath: outPath,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watermark applied successfully!'),
            backgroundColor: AppColors.success500,
          ),
        );
        DocumentOpener.open(context, outFile.path);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply watermark: $e')),
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
        title: const Text('Add Watermark'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Pick PDF Card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickPdf,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.filePdf,
                      child: Icon(LucideIcons.file_text, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPdfPath != null
                                ? p.basename(_selectedPdfPath!)
                                : 'Select PDF Document',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPdfPath != null
                                ? 'Tap to change document'
                                : 'Choose a file to add watermark',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 2. Watermark Text Input
          Text(
            'Watermark Text',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _watermarkController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. CONFIDENTIAL',
              prefixIcon: const Icon(LucideIcons.stamp, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Presets wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((preset) {
              final isSelected = _watermarkController.text == preset;
              return ChoiceChip(
                label: Text(preset),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _watermarkController.text = preset;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // 3. Action button
          DocoraButton(
            label: _isProcessing ? 'Applying Watermark...' : 'Apply Watermark & Export',
            icon: LucideIcons.circle_check,
            isLoading: _isProcessing,
            onPressed: (_selectedPdfPath == null || _isProcessing) ? null : _applyWatermark,
          ),
        ],
      ),
    );
  }
}
