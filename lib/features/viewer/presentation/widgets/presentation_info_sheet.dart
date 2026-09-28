import 'package:docora/features/viewer/domain/models/presentation_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet showing presentation deck properties and metadata.
class PresentationInfoSheet extends StatelessWidget {
  const PresentationInfoSheet({
    required this.document,
    super.key,
  });

  final PresentationDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ratioLabel = document.isWidescreen ? '16:9 Widescreen' : '4:3 Standard';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                LucideIcons.presentation,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Presentation Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: LucideIcons.file,
            label: 'File Name',
            value: document.title,
          ),
          _InfoRow(
            icon: LucideIcons.layers,
            label: 'Total Slides',
            value: document.slideCount.toString(),
          ),
          _InfoRow(
            icon: LucideIcons.ratio,
            label: 'Aspect Ratio',
            value: ratioLabel,
          ),
          _InfoRow(
            icon: LucideIcons.file_text,
            label: 'Speaker Notes',
            value: '${document.notesCount} of ${document.slideCount} slides',
          ),
          _InfoRow(
            icon: LucideIcons.hard_drive,
            label: 'File Size',
            value: _formatBytes(document.fileSizeBytes),
          ),
          _InfoRow(
            icon: LucideIcons.folder,
            label: 'Path',
            value: document.filePath,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isSecondary
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              maxLines: isSecondary ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
