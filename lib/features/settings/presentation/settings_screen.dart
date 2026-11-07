import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/widget_sync.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/app_theme.dart';
import 'package:docora/core/theme/clay_decorations.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Clean, production-grade Settings screen.
/// Structured into 7 clearly separated categories:
/// GENERAL, APPEARANCE, DOCUMENT VIEWER, FILE MANAGEMENT, STORAGE, PRIVACY & SECURITY, and ABOUT.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showSortDialog(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(defaultSortProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Default Sort Order', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          _dialogOption(ctx, 'Date modified (newest first)', 'date_desc', currentSort, (val) {
            ref.read(defaultSortProvider.notifier).setSort(val);
          }),
          _dialogOption(ctx, 'Date modified (oldest first)', 'date_asc', currentSort, (val) {
            ref.read(defaultSortProvider.notifier).setSort(val);
          }),
          _dialogOption(ctx, 'Name (A to Z)', 'name_asc', currentSort, (val) {
            ref.read(defaultSortProvider.notifier).setSort(val);
          }),
          _dialogOption(ctx, 'Name (Z to A)', 'name_desc', currentSort, (val) {
            ref.read(defaultSortProvider.notifier).setSort(val);
          }),
          _dialogOption(ctx, 'File size (largest first)', 'size_desc', currentSort, (val) {
            ref.read(defaultSortProvider.notifier).setSort(val);
          }),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(languageProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          _dialogOption(ctx, 'English', 'en', currentLang, (val) {
            ref.read(languageProvider.notifier).setLanguage(val);
          }),
          _dialogOption(ctx, 'Hindi (हिंदी)', 'hi', currentLang, (val) {
            ref.read(languageProvider.notifier).setLanguage(val);
          }),
        ],
      ),
    );
  }

  void _showStartupDialog(BuildContext context, WidgetRef ref) {
    final currentStartup = ref.read(startupScreenProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Startup Screen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          _dialogOption(ctx, 'Home Dashboard', 'home', currentStartup, (val) {
            ref.read(startupScreenProvider.notifier).setStartup(val);
          }),
          _dialogOption(ctx, 'Files Browser', 'files', currentStartup, (val) {
            ref.read(startupScreenProvider.notifier).setStartup(val);
          }),
        ],
      ),
    );
  }

  SimpleDialogOption _dialogOption(
    BuildContext ctx,
    String label,
    String value,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == current;
    return SimpleDialogOption(
      onPressed: () {
        onSelected(value);
        Navigator.of(ctx).pop();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
          if (isSelected) const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will delete temporary preview files and cached thumbnails. Your original documents will NOT be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final cacheDir = await getTemporaryDirectory();
        if (cacheDir.existsSync()) {
          final items = cacheDir.listSync(recursive: false);
          for (final item in items) {
            try {
              item.deleteSync(recursive: true);
            } catch (_) {}
          }
        }
        ref.invalidate(cacheSizeProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Reading History?'),
        content: const Text(
          'This will reset your recent documents list and saved reading positions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(documentRepositoryProvider);
        await repo.clearRecentHistory();
        await WidgetSync.clearRecentDoc();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recent reading history cleared.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear history: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isAmoled = ref.watch(isAmoledProvider);
    final accentIndex = ref.watch(accentColorIndexProvider);

    final language = ref.watch(languageProvider);
    final defaultSort = ref.watch(defaultSortProvider);
    final defaultView = ref.watch(defaultViewProvider);
    final startup = ref.watch(startupScreenProvider);

    final continuousScroll = ref.watch(continuousScrollingProvider);
    final rememberPosition = ref.watch(rememberReadingPositionProvider);
    final keepScreenAwake = ref.watch(keepScreenAwakeProvider);
    final fullScreenMode = ref.watch(fullScreenModeProvider);

    final showHidden = ref.watch(showHiddenFilesProvider);
    final includeSubs = ref.watch(includeSubfoldersProvider);

    final cacheSizeAsync = ref.watch(cacheSizeProvider);
    final cacheBytes = cacheSizeAsync.valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.md,
        ),
        children: [
          // ── GENERAL ──
          _sectionHeader('GENERAL', LucideIcons.sliders_horizontal, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              _SettingRow(
                icon: LucideIcons.languages,
                title: 'Language',
                subtitle: language == 'hi' ? 'Hindi (हिंदी)' : 'English',
                onTap: () => _showLanguageDialog(context, ref),
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.arrow_up_down,
                title: 'Default Sort Order',
                subtitle: _formatSortName(defaultSort),
                onTap: () => _showSortDialog(context, ref),
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.layout_grid,
                title: 'Default View',
                subtitle: defaultView == 'grid' ? 'Grid view' : 'List view',
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'list', icon: Icon(LucideIcons.list, size: 16)),
                    ButtonSegment(value: 'grid', icon: Icon(LucideIcons.grid_2x2, size: 16)),
                  ],
                  selected: {defaultView},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      ref.read(defaultViewProvider.notifier).setView(set.first);
                    }
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.layout_dashboard,
                title: 'Startup Screen',
                subtitle: startup == 'files' ? 'Files Browser' : 'Home Dashboard',
                onTap: () => _showStartupDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── APPEARANCE ──
          _sectionHeader('APPEARANCE', LucideIcons.palette, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              _SettingRow(
                icon: LucideIcons.sun_moon,
                title: 'Theme',
                subtitle: switch (themeMode) {
                  ThemeMode.light => 'Light theme',
                  ThemeMode.dark => 'Dark theme',
                  _ => 'System default',
                },
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, icon: Icon(LucideIcons.monitor, size: 16)),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(LucideIcons.sun, size: 16)),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(LucideIcons.moon, size: 16)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                    }
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              _divider(colorScheme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.droplets, size: 20, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 16),
                        Text(
                          'Accent Color',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentOptions[accentIndex.clamp(0, AppColors.accentOptions.length - 1)].withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentOptions[accentIndex.clamp(0, AppColors.accentOptions.length - 1)].withAlpha(80),
                            ),
                          ),
                          child: Text(
                            AppColors.accentColorOptions[accentIndex.clamp(0, AppColors.accentColorOptions.length - 1)].name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.accentOptions[accentIndex.clamp(0, AppColors.accentOptions.length - 1)],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        AppColors.accentColorOptions.length,
                        (i) {
                          final isSelected = i == accentIndex;
                          final option = AppColors.accentColorOptions[i];
                          return Tooltip(
                            message: option.name,
                            child: GestureDetector(
                              onTap: () {
                                ref.read(accentColorIndexProvider.notifier).setAccentIndex(i);
                                WidgetSync.syncAccentColor(i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: option.color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: colorScheme.onSurface, width: 3)
                                      : Border.all(color: colorScheme.outline.withAlpha(50), width: 1.5),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: option.color.withAlpha(100),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (themeMode == ThemeMode.dark) ...[
                _divider(colorScheme),
                _SettingSwitchRow(
                  icon: LucideIcons.contrast,
                  title: 'Pure Black (AMOLED)',
                  subtitle: 'True black background for OLED battery savings',
                  value: isAmoled,
                  onChanged: (val) => ref.read(isAmoledProvider.notifier).setAmoled(val),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── DOCUMENT VIEWER ──
          _sectionHeader('DOCUMENT VIEWER', LucideIcons.book_open, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              _SettingSwitchRow(
                icon: LucideIcons.scroll,
                title: 'Continuous Scrolling',
                subtitle: 'Smooth continuous page feed',
                value: continuousScroll,
                onChanged: (val) => ref.read(continuousScrollingProvider.notifier).set(val),
              ),
              _divider(colorScheme),
              _SettingSwitchRow(
                icon: LucideIcons.bookmark,
                title: 'Remember Reading Position',
                subtitle: 'Resume where you paused in books & reports',
                value: rememberPosition,
                onChanged: (val) => ref.read(rememberReadingPositionProvider.notifier).set(val),
              ),
              _divider(colorScheme),
              _SettingSwitchRow(
                icon: LucideIcons.sun,
                title: 'Keep Screen Awake',
                subtitle: 'Prevent display timeout while viewing documents',
                value: keepScreenAwake,
                onChanged: (val) => ref.read(keepScreenAwakeProvider.notifier).set(val),
              ),
              _divider(colorScheme),
              _SettingSwitchRow(
                icon: LucideIcons.maximize_2,
                title: 'Full-screen Mode',
                subtitle: 'Hide system status bars automatically in viewer',
                value: fullScreenMode,
                onChanged: (val) => ref.read(fullScreenModeProvider.notifier).set(val),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── FILE MANAGEMENT ──
          _sectionHeader('FILE MANAGEMENT', LucideIcons.folder, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              _SettingSwitchRow(
                icon: LucideIcons.eye,
                title: 'Show Hidden Files',
                subtitle: 'Files and folders starting with a dot (.)',
                value: showHidden,
                onChanged: (val) => ref.read(showHiddenFilesProvider.notifier).set(val),
              ),
              _divider(colorScheme),
              _SettingSwitchRow(
                icon: LucideIcons.folder_git_2,
                title: 'Include Subfolders',
                subtitle: 'Scan nested directories during discovery',
                value: includeSubs,
                onChanged: (val) => ref.read(includeSubfoldersProvider.notifier).set(val),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── STORAGE ──
          _sectionHeader('STORAGE', LucideIcons.hard_drive, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              _SettingRow(
                icon: LucideIcons.trash,
                title: 'Clear Cache',
                subtitle: '${_formatBytes(cacheBytes)} of temporary files',
                trailing: TextButton(
                  onPressed: () => _clearCache(context, ref),
                  child: const Text('Clear', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── PRIVACY & SECURITY ──
          _sectionHeader('PRIVACY & SECURITY', LucideIcons.shield, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              _SettingRow(
                icon: LucideIcons.clock,
                title: 'Clear Recent History',
                subtitle: 'Remove recently opened document entries',
                onTap: () => _clearHistory(context, ref),
              ),
              _divider(colorScheme),
              const _SettingRow(
                icon: LucideIcons.lock,
                title: 'Offline Guarantee',
                subtitle: 'No internet connection needed. Zero tracking.',
                trailing: Icon(LucideIcons.circle_check, size: 18, color: AppColors.success),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── ABOUT ──
          _sectionHeader('ABOUT', LucideIcons.info, colorScheme.primary),
          _cardContainer(
            context: context,
            colorScheme: colorScheme,
            children: [
              const _SettingRow(
                icon: LucideIcons.tag,
                title: 'App Version',
                subtitle: '1.0.2 — Offline Document Suite',
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.shield_alert,
                title: 'Privacy Policy',
                subtitle: 'Read our zero-data-collection commitment',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.file_check,
                title: 'Terms & Conditions',
                subtitle: 'Service terms and usage guidelines',
                onTap: () => context.push(AppRoutes.termsConditions),
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.code,
                title: 'Open Source Licenses',
                subtitle: 'Inspect bundled open-source components',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Docora',
                  applicationVersion: '1.0.2',
                  applicationLegalese: '© 2026 Docora Contributors. Built with Flutter & Gander Engines.',
                ),
              ),
              _divider(colorScheme),
              _SettingRow(
                icon: LucideIcons.send,
                title: 'Send Feedback',
                subtitle: 'Report a bug or suggest a feature',
                onTap: () async {
                  final uri = Uri.parse('https://github.com');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl * 2),
        ],
      ),
    );
  }

  static String _formatSortName(String sort) {
    switch (sort) {
      case 'date_asc':
        return 'Date modified (oldest first)';
      case 'name_asc':
        return 'Name (A to Z)';
      case 'name_desc':
        return 'Name (Z to A)';
      case 'size_desc':
        return 'File size (largest first)';
      default:
        return 'Date modified (newest first)';
    }
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardContainer({required BuildContext context, required ColorScheme colorScheme, required List<Widget> children}) {
    return DecoratedBox(
      decoration: ClayDecorations.card(
        context,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(height: 1, thickness: 1, color: colorScheme.outline.withAlpha(35));
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(LucideIcons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      value: value,
      activeTrackColor: colorScheme.primary,
      onChanged: onChanged,
    );
  }
}
