import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
                    LucideIcons.file_text,
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
                        'Terms of Service',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last updated: November 2026. Please read carefully.',
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
            title: '1. Acceptance of Terms',
            content:
                'By downloading, installing, or using Docora, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the application.',
          ),

          _buildSection(
            context: context,
            title: '2. License and Usage',
            content:
                'Docora is provided for personal and professional document management, reading, and editing on your compatible devices. You retain full ownership and copyright of all documents and files viewed or created with Docora.',
          ),

          _buildSection(
            context: context,
            title: '3. Offline Nature & User Responsibility',
            content:
                'Because Docora is a completely offline application that does not upload your files to remote servers, you are solely responsible for creating appropriate backups of your important files and documents.',
          ),

          _buildSection(
            context: context,
            title: '4. Open Source Components',
            content:
                'Docora utilizes various open-source libraries under permissive licenses (including Apache-2.0, MIT, and BSD). Third-party license texts can be inspected directly in Settings > Open Source Licenses.',
          ),

          _buildSection(
            context: context,
            title: '5. Disclaimer of Warranties',
            content:
                'Docora is provided "as is" and "as available", without warranties of any kind, whether express or implied. The developers do not warrant that document rendering will be 100% identical to proprietary suites for non-standard formats.',
          ),

          _buildSection(
            context: context,
            title: '6. Limitation of Liability',
            content:
                'In no event shall Docora or its contributors be liable for any indirect, incidental, special, consequential, or punitive damages arising from the use of or inability to use the software.',
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

