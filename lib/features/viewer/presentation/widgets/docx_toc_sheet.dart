import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/viewer/domain/models/docx_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Modal bottom sheet displaying the Table of Contents automatically extracted from Headings.
class DocxTocSheet extends StatelessWidget {
  const DocxTocSheet({
    required this.headings,
    required this.onHeadingSelected,
    super.key,
  });

  final List<DocxHeading> headings;
  final ValueChanged<int> onHeadingSelected;

  static void show({
    required BuildContext context,
    required List<DocxHeading> headings,
    required ValueChanged<int> onHeadingSelected,
  }) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Table of Contents',
      subtitle: '${headings.length} sections found',
      showCloseButton: true,
      builder: (_) => DocxTocSheet(
        headings: headings,
        onHeadingSelected: onHeadingSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (headings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.list_x,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(120),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No Table of Contents',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This document does not contain formatted heading styles (Heading 1-3).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: headings.length,
        itemBuilder: (context, index) {
          final heading = headings[index];
          final indent = (heading.level - 1).clamp(0, 3) * 16.0;

          return ListTile(
            contentPadding: EdgeInsets.only(
              left: AppSpacing.md + indent,
              right: AppSpacing.md,
            ),
            leading: Icon(
              heading.level == 1 ? LucideIcons.heading_1 : LucideIcons.heading_2,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              heading.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: heading.level == 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onHeadingSelected(heading.blockIndex);
            },
          );
        },
      ),
    );
  }
}
