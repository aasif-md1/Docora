import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/clay_decorations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

/// Tools tab — Complete suite of offline PDF & Document Utilities.
/// Refined with the Centralized Master Design System:
/// Clean neutral surfaces, consistent primary accents, and unified card geometry.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tools & Utilities'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.25,
              children: [
                _ToolCard(
                  icon: LucideIcons.image,
                  label: 'Image to PDF',
                  subtitle: 'Combine photos into PDF',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.imageToPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.merge,
                  label: 'Merge PDFs',
                  subtitle: 'Combine multiple files',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.mergePdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.scissors,
                  label: 'Split PDF',
                  subtitle: 'Divide or extract pages',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.splitPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.stamp,
                  label: 'Watermark',
                  subtitle: 'Stamp text watermark',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.watermarkPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.file_down,
                  label: 'Compress PDF',
                  subtitle: 'Reduce document size',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.compressPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.folder_heart,
                  label: 'Collections',
                  subtitle: 'Organize into categories',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.collections);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.scan_line,
                  label: 'Doc Scanner',
                  subtitle: 'Camera scan & crop',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.scanner);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.shield_check,
                  label: 'Private Vault',
                  subtitle: 'Biometric locked docs',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.vault);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.trash,
                  label: 'Recycle Bin',
                  subtitle: 'Restore deleted files',
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.recycleBin);
                  },
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: ClayDecorations.card(
        context,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: colorScheme.primary),
                ),
                const Spacer(),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
