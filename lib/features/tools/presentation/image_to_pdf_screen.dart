import 'dart:io';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/pdf_tools_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:docora/features/tools/presentation/widgets/image_crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Represents an individual image entry with its crop and rotation state.
class ImageItemEntry {
  ImageItemEntry({
    required this.originalPath,
    String? currentPath,
    this.quarterTurns = 0,
  }) : currentPath = currentPath ?? originalPath;

  final String originalPath;
  String currentPath;
  int quarterTurns; // 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270°

  int get rotationDegrees => (quarterTurns % 4) * 90;

  void rotateClockwise() {
    quarterTurns = (quarterTurns + 1) % 4;
  }
}

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<ImageItemEntry> _items = [];
  final ImagePicker _picker = ImagePicker();
  final PdfToolsService _toolsService = const PdfToolsService();
  bool _isConverting = false;

  Future<void> _pickImages(ImageSource source) async {
    AppMotion.subtleHaptic();
    try {
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 95);
        if (photo != null) {
          setState(() => _items.add(ImageItemEntry(originalPath: photo.path)));
        }
      } else {
        final picked = await _picker.pickMultiImage(imageQuality: 95);
        if (picked.isNotEmpty) {
          setState(() {
            _items.addAll(picked.map((e) => ImageItemEntry(originalPath: e.path)));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick images: $e')),
        );
      }
    }
  }

  void _rotateImage(int index) {
    AppMotion.subtleHaptic();
    setState(() {
      _items[index].rotateClockwise();
    });
  }

  Future<void> _cropImage(int index) async {
    AppMotion.subtleHaptic();
    final item = _items[index];
    final croppedPath = await ImageCropScreen.show(context, item.currentPath);
    if (croppedPath != null && mounted) {
      setState(() {
        item.currentPath = croppedPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image cropped successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeImage(int index) {
    AppMotion.subtleHaptic();
    setState(() => _items.removeAt(index));
  }

  Future<void> _convertToPdf() async {
    if (_items.isEmpty) return;
    AppMotion.subtleHaptic();
    setState(() => _isConverting = true);

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${docDir.path}/Docora_Images_$timestamp.pdf';

      final imagePaths = _items.map((e) => e.currentPath).toList();
      final rotations = _items.map((e) => e.quarterTurns).toList();

      final outFile = await _toolsService.imagesToPdf(
        imagePaths: imagePaths,
        rotationsQuarterTurns: rotations,
        outputPath: outPath,
      );

      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF successfully generated!'),
            backgroundColor: AppColors.success500,
          ),
        );
        // Open the newly created PDF immediately in Docora
        DocumentOpener.open(context, outFile.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
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
        title: const Text('Images to PDF'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _items.clear()),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons: Camera & Gallery
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImages(ImageSource.camera),
                    icon: const Icon(LucideIcons.camera, size: 18),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickImages(ImageSource.gallery),
                    icon: const Icon(LucideIcons.images, size: 18),
                    label: const Text('Add Images'),
                  ),
                ),
              ],
            ),
          ),

          // Images Reorderable List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.images, size: 64, color: colorScheme.outlineVariant),
                          const SizedBox(height: AppSpacing.md),
                          Text('No images added yet', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Add single or multiple images, crop & rotate each image individually, and create high quality PDF',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    itemCount: _items.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        var targetIdx = newIdx;
                        if (targetIdx > oldIdx) targetIdx -= 1;
                        final item = _items.removeAt(oldIdx);
                        _items.insert(targetIdx, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final file = File(item.currentPath);
                      final fileName = item.currentPath.split(Platform.pathSeparator).last;

                      return Card(
                        key: ValueKey('${item.currentPath}_${item.quarterTurns}_$index'),
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              // Rotated Image Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.black12,
                                  child: RotatedBox(
                                    quarterTurns: item.quarterTurns,
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.image_off, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Page Info & Rotation Tag
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Page ${index + 1}',
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        if (item.quarterTurns % 4 != 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary500.withAlpha(25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.rotationDegrees}°',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Action Buttons: Crop & Rotate
                              IconButton(
                                icon: const Icon(LucideIcons.crop, size: 18),
                                tooltip: 'Crop image',
                                onPressed: () => _cropImage(index),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.rotate_cw, size: 18),
                                tooltip: 'Rotate 90°',
                                onPressed: () => _rotateImage(index),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash, size: 18, color: AppColors.error500),
                                tooltip: 'Delete',
                                onPressed: () => _removeImage(index),
                              ),
                              const Icon(LucideIcons.grip_vertical, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Convert Action
          if (_items.isNotEmpty)
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
                label: _isConverting
                    ? 'Generating PDF...'
                    : 'Generate PDF (${_items.length} ${_items.length == 1 ? "page" : "pages"})',
                icon: LucideIcons.file_check,
                isLoading: _isConverting,
                onPressed: _isConverting ? null : _convertToPdf,
              ),
            ),
        ],
      ),
    );
  }
}
