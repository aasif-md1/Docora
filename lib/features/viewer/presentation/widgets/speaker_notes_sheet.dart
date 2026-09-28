import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet showing speaker notes for the active presentation slide.
class SpeakerNotesSheet extends StatelessWidget {
  const SpeakerNotesSheet({
    required this.slideIndex,
    required this.notes,
    super.key,
  });

  final int slideIndex;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNotes = notes != null && notes!.trim().isNotEmpty;

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
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Speaker Notes (Slide ${slideIndex + 1})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasNotes)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: SelectableText(
                  notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.message_square_off,
                      size: 36,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No speaker notes for this slide',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
