import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings tab — live theme switching implemented, full settings in Phase 10
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isAmoled = ref.watch(isAmoledProvider);
    final accentIndex = ref.watch(accentColorIndexProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Settings'),
            floating: true,
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Appearance Section ──
                const _SectionHeader(title: 'Appearance', icon: LucideIcons.palette),
                const SizedBox(height: AppSpacing.sm),

                // Theme mode selector
                Card(
                  child: Column(
                    children: [
                      _ThemeOption(
                        icon: LucideIcons.monitor,
                        label: 'System default',
                        isSelected: themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                      const Divider(height: 1),
                      _ThemeOption(
                        icon: LucideIcons.sun,
                        label: 'Light',
                        isSelected: themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      const Divider(height: 1),
                      _ThemeOption(
                        icon: LucideIcons.moon,
                        label: 'Dark',
                        isSelected: themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                      const Divider(height: 1),
                      _ThemeOption(
                        icon: LucideIcons.contrast,
                        label: 'AMOLED (Pure Black)',
                        subtitle: 'Saves battery on OLED screens',
                        isSelected: isAmoled && themeMode == ThemeMode.dark,
                        onTap: () {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                              ThemeMode.dark);
                          ref.read(isAmoledProvider.notifier).toggle();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                const _SectionHeader(title: 'Accent Color', icon: LucideIcons.droplets),
                const SizedBox(height: AppSpacing.md),

                // Accent color picker
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List.generate(
                    AppColors.accentOptions.length,
                    (i) => GestureDetector(
                      onTap: () => ref
                          .read(accentColorIndexProvider.notifier)
                          .setAccentIndex(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentOptions[i],
                          shape: BoxShape.circle,
                          border: i == accentIndex
                              ? Border.all(
                                  color: colorScheme.onSurface,
                                  width: 2.5,
                                )
                              : null,
                          boxShadow: i == accentIndex
                              ? [
                                  BoxShadow(
                                    color: AppColors.accentOptions[i]
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: i == accentIndex
                            ? const Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
                const _SectionHeader(title: 'Design System', icon: LucideIcons.palette),
                const SizedBox(height: AppSpacing.sm),

                Card(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.layout_template,
                        title: 'Component Gallery',
                        subtitle: 'Preview badges, buttons, cards, list items & AMOLED tokens',
                        onTap: () => context.push(AppRoutes.componentGallery),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
                const _SectionHeader(title: 'About', icon: LucideIcons.info),
                const SizedBox(height: AppSpacing.sm),

                Card(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.shield,
                        title: 'Privacy Policy',
                        subtitle: 'No ads. No tracking. No data collection.',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: LucideIcons.code,
                        title: 'Open Source Licenses',
                        onTap: () => showLicensePage(context: context),
                      ),
                      const Divider(height: 1),
                      const _SettingsTile(
                        icon: LucideIcons.info,
                        title: 'Version',
                        subtitle: '1.0.0 — Offline Document Suite',
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: isSelected
          ? Icon(LucideIcons.circle_check, color: colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(title, style: textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
    );
  }
}
