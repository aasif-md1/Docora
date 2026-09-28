import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal dialog prompting the user for password to unlock an encrypted PDF document.
class PdfPasswordDialog extends StatefulWidget {
  const PdfPasswordDialog({
    this.errorMessage,
    super.key,
  });

  final String? errorMessage;

  static Future<String?> show(
    BuildContext context, {
    String? errorMessage,
  }) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PdfPasswordDialog(errorMessage: errorMessage),
      );

  @override
  State<PdfPasswordDialog> createState() => _PdfPasswordDialogState();
}

class _PdfPasswordDialogState extends State<PdfPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.errorMessage;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _error = 'Please enter a password';
      });
      return;
    }
    Navigator.of(context).pop(password);
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
        LucideIcons.lock_keyhole,
        color: colorScheme.primary,
        size: 32,
      ),
      title: const Text('Password Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This PDF document is encrypted. Enter password to view its contents.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: 'Password',
              errorText: _error,
              prefixIcon: const Icon(LucideIcons.key_round, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? LucideIcons.eye : LucideIcons.eye_off,
                  size: 20,
                ),
                tooltip: _obscureText ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
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
          label: 'Unlock',
          icon: LucideIcons.lock_keyhole_open,
          size: DocoraButtonSize.small,
          onPressed: _submit,
        ),
      ],
    );
  }
}
