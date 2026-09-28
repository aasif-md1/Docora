import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pdfrx/pdfrx.dart';

/// Modal bottom sheet displaying the PDF Table of Contents (outline tree).
class PdfOutlineSheet extends StatelessWidget {
  const PdfOutlineSheet({
    required this.outline,
    required this.onPageSelected,
    super.key,
  });

  final List<PdfOutlineNode> outline;
  final ValueChanged<int> onPageSelected;

  static void show({
    required BuildContext context,
    required List<PdfOutlineNode> outline,
    required ValueChanged<int> onPageSelected,
  }) {
    DocoraBottomSheet.show<void>(
      context: context,
      title: 'Table of Contents',
      subtitle: '${outline.length} top-level chapters',
      showCloseButton: true,
      builder: (_) => PdfOutlineSheet(
        outline: outline,
        onPageSelected: onPageSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (outline.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.bookmark_x,
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
                'This PDF document does not contain an embedded outline or bookmarks.',
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
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        children: _buildNodes(context, outline, level: 0),
      ),
    );
  }

  List<Widget> _buildNodes(
    BuildContext context,
    List<PdfOutlineNode> nodes, {
    required int level,
  }) {
    final list = <Widget>[];

    for (final node in nodes) {
      final targetPage = node.dest?.pageNumber;
      final hasChildren = node.children.isNotEmpty;

      if (hasChildren) {
        list.add(
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.only(
                left: AppSpacing.md + (level * 16.0),
                right: AppSpacing.md,
              ),
              leading: Icon(
                LucideIcons.bookmark,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                node.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              trailing: targetPage != null
                  ? Text(
                      'p. $targetPage',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  : null,
              children: _buildNodes(context, node.children, level: level + 1),
            ),
          ),
        );
      } else {
        list.add(
          ListTile(
            contentPadding: EdgeInsets.only(
              left: AppSpacing.md + (level * 16.0),
              right: AppSpacing.md,
            ),
            leading: Icon(
              LucideIcons.file_text,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              node.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: targetPage != null
                ? Text(
                    'p. $targetPage',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  )
                : null,
            onTap: () {
              if (targetPage != null) {
                Navigator.of(context).pop();
                onPageSelected(targetPage);
              }
            },
          ),
        );
      }
    }

    return list;
  }
}
