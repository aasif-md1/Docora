import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:docora/core/widgets/document_format_badge.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

/// Modal dialog displaying full file metadata, path, and hash checksums.
/// Adheres strictly to Docora's zero-emoji guideline.
class FileDetailsDialog extends StatefulWidget {
  const FileDetailsDialog({required this.document, super.key});

  final DocumentEntity document;

  static Future<void> show(BuildContext context, DocumentEntity doc) {
    AppMotion.subtleHaptic();
    return showDialog(
      context: context,
      builder: (ctx) => FileDetailsDialog(document: doc),
    );
  }

  @override
  State<FileDetailsDialog> createState() => _FileDetailsDialogState();
}

class _FileDetailsDialogState extends State<FileDetailsDialog> {
  String? _md5Hash;
  bool _isCalculatingHash = false;

  Future<void> _calculateHash() async {
    setState(() => _isCalculatingHash = true);
    try {
      final file = File(widget.document.path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final digest = md5.convert(bytes);
        if (mounted) {
          setState(() => _md5Hash = digest.toString());
        }
      } else {
        if (mounted) {
          setState(() => _md5Hash = 'File does not exist on disk');
        }
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _md5Hash = 'Error calculating hash');
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculatingHash = false);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    AppMotion.subtleHaptic();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doc = widget.document;
    final format = DocumentFormat.fromExtension(doc.extension);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      title: Row(
        children: [
          DocumentFormatBadge(format: format),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'File Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              context,
              icon: LucideIcons.file,
              label: 'File Name',
              value: doc.name,
              copyable: true,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: LucideIcons.folder,
              label: 'File Path',
              value: doc.path,
              copyable: true,
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: LucideIcons.hard_drive,
              label: 'File Size',
              value: '${doc.formattedSize} (${doc.sizeBytes} bytes)',
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: LucideIcons.calendar,
              label: 'Last Modified',
              value: DateFormat.yMMMMd().add_jms().format(doc.lastModified),
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              icon: LucideIcons.layers,
              label: 'MIME Type',
              value: doc.mimeType,
            ),
            const Divider(height: AppSpacing.lg),

            // MD5 Hash Inspector
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.shield_check,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MD5 CHECKSUM',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_md5Hash != null)
                        InkWell(
                          onTap: () => _copyToClipboard(_md5Hash!, 'MD5'),
                          child: Text(
                            _md5Hash!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      else if (_isCalculatingHash)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        GestureDetector(
                          onTap: _calculateHash,
                          child: Text(
                            'Tap to compute checksum',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        DocoraButton(
          label: 'Close',
          variant: DocoraButtonVariant.secondary,
          size: DocoraButtonSize.small,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 16),
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy $label',
            onPressed: () => _copyToClipboard(value, label),
          ),
      ],
    );
  }
}
