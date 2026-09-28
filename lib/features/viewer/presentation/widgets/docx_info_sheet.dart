import 'dart:io';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Modal sheet displaying comprehensive Word document statistics and properties.
class DocxInfoSheet extends StatelessWidget {
  const DocxInfoSheet({
    required this.filePath,
    required this.document,
    super.key,
  });

  final String filePath;
  final DocxDocument document;

  static void show({
    required BuildContext context,
    required String filePath,
    required DocxDocument document,
  }) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Document Properties',
      subtitle: p.basename(filePath),
      showCloseButton: true,
      builder: (_) => DocxInfoSheet(
        filePath: filePath,
        document: document,
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    int fileSize = 0;
    DateTime? modified;

    try {
      if (file.existsSync()) {
        final stat = file.statSync();
        fileSize = stat.size;
        modified = stat.modified;
      }
    } on Object catch (_) {}

    final dateFormatted = modified != null
        ? DateFormat('MMM d, y • h:mm a').format(modified)
        : 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DocoraActionTile(
            icon: LucideIcons.file_text,
            title: 'File Name',
            subtitle: p.basename(filePath),
          ),
          DocoraActionTile(
            icon: LucideIcons.folder,
            title: 'Location',
            subtitle: p.dirname(filePath),
          ),
          DocoraActionTile(
            icon: LucideIcons.hard_drive,
            title: 'File Size',
            subtitle: _formatBytes(fileSize),
          ),
          DocoraActionTile(
            icon: LucideIcons.type,
            title: 'Word Count',
            subtitle: '${document.wordCount} words (${document.characterCount} characters)',
          ),
          DocoraActionTile(
            icon: LucideIcons.clock,
            title: 'Estimated Reading Time',
            subtitle: '${document.estimatedReadingMinutes} min read',
          ),
          DocoraActionTile(
            icon: LucideIcons.list_tree,
            title: 'Headings / Sections',
            subtitle: '${document.headings.length} sections',
          ),
          DocoraActionTile(
            icon: LucideIcons.image,
            title: 'Embedded Images',
            subtitle: '${document.images.length} images',
          ),
          DocoraActionTile(
            icon: LucideIcons.calendar,
            title: 'Last Modified',
            subtitle: dateFormatted,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
