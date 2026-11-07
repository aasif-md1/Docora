import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.shield_check,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your documents never leave your device. No cloud. No tracking.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _buildSection(
            context: context,
            title: '1. Zero Data Collection',
            content:
                'Docora does not collect, log, track, or transmit any personally identifiable information, file metadata, reading activity, or document content. The app operates completely offline without analytics SDKs, advertising networks, or background telemetry.',
          ),

          _buildSection(
            context: context,
            title: '2. Local Document Storage & SAF',
            content:
                'Documents viewed or edited in Docora are read directly from your local filesystem or via Android Storage Access Framework (SAF). Docora never uploads files to external servers or cloud storage.',
          ),

          _buildSection(
            context: context,
            title: '3. Sandboxed Offline Document Viewer',
            content:
                'Office files (Word, Excel, PowerPoint) and PDFs are parsed strictly locally inside isolated offline renderer environments. No network requests are made, and no content is ever communicated outside your device.',
          ),

          _buildSection(
            context: context,
            title: '4. Local Cache & Temporary Files',
            content:
                'Temporary rendering caches created during document viewing reside exclusively in your app-private cache directory. You can permanently clear all cached data at any time in Settings > Storage > Clear Cache.',
          ),

          _buildSection(
            context: context,
            title: '5. Device Permissions',
            content:
                'Docora requests only permissions necessary for file discovery and viewing on Android. You maintain complete control over granted permissions through your device system settings.',
          ),

          _buildSection(
            context: context,
            title: '6. Policy Updates & Contact',
            content:
                'Any updates to this policy will be documented in the app release notes. If you have questions regarding this privacy policy, you can contact the Docora team directly via GitHub.',
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

