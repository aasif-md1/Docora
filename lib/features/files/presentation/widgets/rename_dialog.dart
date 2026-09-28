import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;

/// Dialog for renaming an existing document file.
class RenameDialog extends StatefulWidget {
  const RenameDialog({required this.document, super.key});

  final DocumentEntity document;

  static Future<String?> show(BuildContext context, DocumentEntity doc) {
    AppMotion.subtleHaptic();
    return showDialog<String>(
      context: context,
      builder: (ctx) => RenameDialog(document: doc),
    );
  }

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate with base name without extension
    final baseName = p.basenameWithoutExtension(widget.document.name);
    _controller = TextEditingController(text: baseName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'File name cannot be empty');
      return;
    }

    // Check invalid characters
    final illegalChars = RegExp(r'[<>:"/\\|?*]');
    if (illegalChars.hasMatch(text)) {
      setState(() => _errorMessage = r'Name contains illegal characters (<>:"/\|?*)');
      return;
    }

    final newFullName = '$text.${widget.document.extension}';
    Navigator.of(context).pop(newFullName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          Icon(LucideIcons.pencil, size: 20, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Rename File',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter new file name',
              suffixText: '.${widget.document.extension}',
              errorText: _errorMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        DocoraButton(
          label: 'Cancel',
          variant: DocoraButtonVariant.ghost,
          size: DocoraButtonSize.small,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: AppSpacing.xs),
        DocoraButton(
          label: 'Rename',
          size: DocoraButtonSize.small,
          onPressed: _submit,
        ),
      ],
    );
  }
}
