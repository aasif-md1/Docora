import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal dialog allowing direct jumping to a specific page number (1 to totalPages).
class PageJumpDialog extends StatefulWidget {
  const PageJumpDialog({
    required this.currentPage,
    required this.totalPages,
    super.key,
  });

  final int currentPage;
  final int totalPages;

  static Future<int?> show(
    BuildContext context, {
    required int currentPage,
    required int totalPages,
  }) =>
      showDialog<int>(
        context: context,
        builder: (_) => PageJumpDialog(
          currentPage: currentPage,
          totalPages: totalPages,
        ),
      );

  @override
  State<PageJumpDialog> createState() => _PageJumpDialogState();
}

class _PageJumpDialogState extends State<PageJumpDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    final page = int.tryParse(text);

    if (page == null || page < 1 || page > widget.totalPages) {
      setState(() {
        _errorText = 'Enter a valid page between 1 and ${widget.totalPages}';
      });
      return;
    }

    Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      icon: Icon(
        LucideIcons.file_text,
        color: colorScheme.primary,
        size: 28,
      ),
      title: const Text('Jump to Page'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter a page number between 1 and ${widget.totalPages}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            decoration: InputDecoration(
              errorText: _errorText,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        DocoraButton(
          label: 'Go',
          icon: LucideIcons.arrow_right,
          size: DocoraButtonSize.small,
          onPressed: _submit,
        ),
      ],
    );
  }
}
