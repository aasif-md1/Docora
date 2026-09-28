import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet displaying detailed text and code file statistics.
class TextStatsSheet extends StatelessWidget {
  const TextStatsSheet({
    required this.document,
    super.key,
  });

  final TextDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                LucideIcons.file_text,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'File Details & Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StatRow(
            icon: LucideIcons.file,
            label: 'File Name',
            value: document.fileName,
          ),
          _StatRow(
            icon: LucideIcons.code,
            label: 'Language',
            value: document.languageLabel,
          ),
          _StatRow(
            icon: LucideIcons.rows_3,
            label: 'Lines',
            value: _formatNumber(document.lineCount),
          ),
          _StatRow(
            icon: LucideIcons.type,
            label: 'Words',
            value: _formatNumber(document.wordCount),
          ),
          _StatRow(
            icon: LucideIcons.hash,
            label: 'Characters',
            value: _formatNumber(document.characterCount),
          ),
          _StatRow(
            icon: LucideIcons.binary,
            label: 'Encoding',
            value: document.encodingName,
          ),
          _StatRow(
            icon: LucideIcons.hard_drive,
            label: 'File Size',
            value: _formatBytes(document.fileSizeBytes),
          ),
          _StatRow(
            icon: LucideIcons.folder,
            label: 'Path',
            value: document.filePath,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int number) =>
      number.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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
