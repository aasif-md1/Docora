import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:flutter/material.dart';

enum BadgeSize { small, medium, large }

/// DocumentFormatBadge displays a colored indicator chip or icon badge
/// for a document's format (PDF, Word, Excel, etc.) without emoji.
class DocumentFormatBadge extends StatelessWidget {
  const DocumentFormatBadge({
    required this.format,
    super.key,
    this.size = BadgeSize.medium,
    this.showLabel = true,
  });

  factory DocumentFormatBadge.fromExtension(
    String ext, {
    Key? key,
    BadgeSize size = BadgeSize.medium,
    bool showLabel = true,
  }) => DocumentFormatBadge(
      key: key,
      format: DocumentFormat.fromExtension(ext),
      size: size,
      showLabel: showLabel,
    );

  final DocumentFormat format;
  final BadgeSize size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final double iconSize;
    final double fontSize;
    final EdgeInsets padding;
    final double radius;

    switch (size) {
      case BadgeSize.small:
        iconSize = 12;
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        radius = AppRadius.xs;
      case BadgeSize.medium:
        iconSize = 16;
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        radius = AppRadius.sm;
      case BadgeSize.large:
        iconSize = 20;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
        radius = AppRadius.md;
    }

    final bg = format.color.withValues(alpha: 0.15);
    final border = format.color.withValues(alpha: 0.35);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(format.icon, size: iconSize, color: format.color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              format.label.toUpperCase(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: format.color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
