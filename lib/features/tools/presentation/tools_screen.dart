import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

/// Tools tab — Complete suite of offline PDF & Document Utilities
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Tools & Utilities'),
            floating: true,
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
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
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.imageToPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.merge,
                  label: 'Merge PDFs',
                  subtitle: 'Combine multiple documents',
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.mergePdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.scissors,
                  label: 'Split PDF',
                  subtitle: 'Divide or extract pages',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.splitPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.stamp,
                  label: 'Watermark',
                  subtitle: 'Stamp text watermark',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.watermarkPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.file_down,
                  label: 'Compress PDF',
                  subtitle: 'Reduce file size',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.compressPdf);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.folder_heart,
                  label: 'Collections',
                  subtitle: 'Organize your documents',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.collections);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.scan_line,
                  label: 'Doc Scanner',
                  subtitle: 'Camera scan & OCR',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.scanner);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.shield_check,
                  label: 'Private Vault',
                  subtitle: 'Biometric & AES lock',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.vault);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.layout_grid,
                  label: 'Home Widgets',
                  subtitle: 'Scanner, Tools & Hub',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.widgets);
                  },
                ),
                _ToolCard(
                  icon: LucideIcons.trash,
                  label: 'Recycle Bin',
                  subtitle: 'Deleted file recovery',
                  color: const Color(0xFF6B7280),
                  onTap: () {
                    AppMotion.subtleHaptic();
                    context.push(AppRoutes.recycleBin);
                  },
                ),
              ],
            ),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
