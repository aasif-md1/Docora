import 'package:docora/features/viewer/domain/models/spreadsheet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Floating bottom statistics toolbar displaying Count, Sum, Average, Min, and Max
/// for the currently selected cell/column.
class SpreadsheetStatsBar extends StatelessWidget {
  const SpreadsheetStatsBar({
    required this.stats,
    super.key,
  });

  final SpreadsheetStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.count == 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatItem(
              icon: LucideIcons.hash,
              label: 'Count',
              value: stats.count.toString(),
            ),
            if (stats.hasNumeric) ...[
              const _Divider(),
              _StatItem(
                icon: LucideIcons.sigma,
                label: 'Sum',
                value: _formatNumber(stats.sum),
              ),
              const _Divider(),
              _StatItem(
                icon: LucideIcons.chart_pie,
                label: 'Avg',
                value: _formatNumber(stats.average),
              ),
              const _Divider(),
              _StatItem(
                icon: LucideIcons.arrow_down,
                label: 'Min',
                value: _formatNumber(stats.min),
              ),
              const _Divider(),
              _StatItem(
                icon: LucideIcons.arrow_up,
                label: 'Max',
                value: _formatNumber(stats.max),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.outlineVariant,
    );
  }
}
