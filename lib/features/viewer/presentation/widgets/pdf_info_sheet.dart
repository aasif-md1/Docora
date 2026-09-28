import 'dart:io';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Modal sheet displaying comprehensive document metadata and file properties.
class PdfInfoSheet extends StatelessWidget {
  const PdfInfoSheet({
    required this.filePath,
    required this.pageCount,
    required this.isEncrypted,
    super.key,
  });

  final String filePath;
  final int pageCount;
  final bool isEncrypted;

  static void show({
    required BuildContext context,
    required String filePath,
    required int pageCount,
    required bool isEncrypted,
  }) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Document Properties',
      subtitle: p.basename(filePath),
      showCloseButton: true,
      builder: (_) => PdfInfoSheet(
        filePath: filePath,
        pageCount: pageCount,
        isEncrypted: isEncrypted,
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

    return Padding(
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
            icon: LucideIcons.layers,
            title: 'Total Pages',
            subtitle: '$pageCount pages',
          ),
          DocoraActionTile(
            icon: LucideIcons.calendar,
            title: 'Last Modified',
            subtitle: dateFormatted,
          ),
          DocoraActionTile(
            icon: isEncrypted ? LucideIcons.lock : LucideIcons.lock_open,
            title: 'Encryption',
            subtitle: isEncrypted ? 'Password protected' : 'None',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
