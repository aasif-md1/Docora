import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/intent_service.dart';
import 'package:docora/core/services/storage_permission_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_radius.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:docora/features/viewer/domain/models/text_document_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';

/// Reactive Home Dashboard screen.
/// Displays quick format cards with real counts, recent documents, and storage stats.
/// Designed with Emil Kowalski's philosophy: staggered enter animations,
/// custom easing curves, and premium visual polish.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  /// Creates a staggered animation for list items entering the screen.
  /// Each item has a slight delay creating a cascade effect.
  Animation<double> _staggerAnimation(int index, {int total = 5}) {
    final start = (index / total).clamp(0.0, 1.0);
    final end = ((index + 1.5) / total).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: AppMotion.enter),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _onCategoryTap(BuildContext context, WidgetRef ref, String category) {
    AppMotion.subtleHaptic();
    ref.read(selectedCategoryProvider.notifier).state = category;
    context.go(AppRoutes.files);
  }

  @override
  Widget build(BuildContext context) {
    // Check if an external document intent was received
    ref.listen<String?>(pendingOpenDocumentProvider, (_, pending) {
      if (pending != null && pending.isNotEmpty) {
        ref.read(pendingOpenDocumentProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            DocumentOpener.open(context, pending);
          }
        });
      }
    });


    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recentDocsAsync = ref.watch(recentDocumentsProvider);
    final categoryCountsAsync = ref.watch(categoryCountsProvider);
    final totalStorageBytesAsync = ref.watch(totalStorageBytesProvider);
    final isScanning = ref.watch(isScanningProvider);

    final counts = categoryCountsAsync.valueOrNull ?? {};
    final totalBytes = totalStorageBytesAsync.valueOrNull ?? 0;
    final totalDocs = counts['all'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            tooltip: 'Search documents',
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(LucideIcons.scan_line),
            tooltip: 'Scan storage',
            onPressed: () async {
              final granted =
                  await StoragePermissionService.showRationaleSheet(context);
              if (granted) {
                final service = ref.read(storagePermissionServiceProvider);
                final status = await service.requestPermission();
                if (status == StoragePermissionState.granted) {
                  final count = await ref
                      .read(filesControllerProvider.notifier)
                      .scanDeviceStorage();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Discovered $count documents.')),
                    );
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.layout_grid),
            tooltip: 'Desktop Widgets',
            onPressed: () => context.push(AppRoutes.widgets),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(filesControllerProvider.notifier)
              .scanDeviceStorage();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 2),
          children: [
            if (isScanning)
              const LinearProgressIndicator(minHeight: 3),

            // Section 1: Storage Overview Hero Banner — staggered enter
            _StaggeredFadeSlide(
              animation: _staggerAnimation(0),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: DocoraCard(
                  variant: DocoraCardVariant.elevated,
                  backgroundColor: colorScheme.primaryContainer.withAlpha(90),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withAlpha(40),
                              colorScheme.primary.withAlpha(20),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.hard_drive,
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
                              '$totalDocs Documents Indexed',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Using ${_formatBytes(totalBytes)} offline storage',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DocoraButton(
                        label: 'View',
                        size: DocoraButtonSize.small,
                        onPressed: () => context.go(AppRoutes.files),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section 2: Quick Format Categories — staggered enter
            _StaggeredFadeSlide(
              animation: _staggerAnimation(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'CATEGORIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            _StaggeredFadeSlide(
              animation: _staggerAnimation(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    _CategoryTile(
                      title: 'PDF',
                      count: counts['pdf'] ?? 0,
                      color: AppColors.filePdf,
                      icon: LucideIcons.file_text,
                      onTap: () => _onCategoryTap(context, ref, 'pdf'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CategoryTile(
                      title: 'Word',
                      count: counts['word'] ?? 0,
                      color: AppColors.fileWord,
                      icon: LucideIcons.file_pen,
                      onTap: () => _onCategoryTap(context, ref, 'word'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CategoryTile(
                      title: 'Excel',
                      count: counts['excel'] ?? 0,
                      color: AppColors.fileExcel,
                      icon: LucideIcons.file_spreadsheet,
                      onTap: () => _onCategoryTap(context, ref, 'excel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CategoryTile(
                      title: 'PPT',
                      count: counts['ppt'] ?? 0,
                      color: AppColors.filePpt,
                      icon: LucideIcons.file_play,
                      onTap: () => _onCategoryTap(context, ref, 'ppt'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Section 2.5: Android Desktop Widgets Feature Banner — staggered enter
            _StaggeredFadeSlide(
              animation: _staggerAnimation(2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _WidgetsBanner(colorScheme: colorScheme, theme: theme),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Section 3: Recent Documents — staggered enter
            _StaggeredFadeSlide(
              animation: _staggerAnimation(3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT DOCUMENTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.files),
                      child: Text(
                        'View all',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _StaggeredFadeSlide(
              animation: _staggerAnimation(4),
              child: recentDocsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: DocumentListItemSkeleton(),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err'),
                ),
                data: (recentDocs) {
                  if (recentDocs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: DocoraCard(
                        variant: DocoraCardVariant.outlined,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 36,
                              color: colorScheme.onSurfaceVariant.withAlpha(120),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No Recent Activity',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Documents you open will appear here for fast access.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DocoraButton(
                              label: 'Browse Files',
                              icon: LucideIcons.folder,
                              size: DocoraButtonSize.small,
                              onPressed: () => context.go(AppRoutes.files),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: recentDocs.take(5).map((doc) => DocumentListItem(
                      document: doc,
                      onTap: () {
                        ref
                            .read(filesControllerProvider.notifier)
                            .markOpened(doc);
                        DocumentOpener.open(context, doc.path);
                      },
                      onFavoriteToggle: () {
                        ref
                            .read(filesControllerProvider.notifier)
                            .toggleFavorite(doc);
                      },
                    )).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable staggered fade+slide animation wrapper.
/// Elements slide up 16px and fade in — never scale from 0.
/// Uses custom ease-out curve for that instant-response feel.
class _StaggeredFadeSlide extends StatelessWidget {
  const _StaggeredFadeSlide({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Category tile with press-scale feedback and gradient icon background.
class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppMotion.instant,
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(
      parent: _pressController,
      curve: AppMotion.enter,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (context, child) => Transform.scale(
            scale: _pressScale.value,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: widget.color.withAlpha(15),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.color.withAlpha(35),
              ),
              // Subtle glow shadow instead of hard border
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Gradient circle behind icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withAlpha(30),
                        widget.color.withAlpha(15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 20, color: widget.color),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.count}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widgets feature banner with press-scale and premium gradient styling.
class _WidgetsBanner extends StatefulWidget {
  const _WidgetsBanner({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  State<_WidgetsBanner> createState() => _WidgetsBannerState();
}

class _WidgetsBannerState extends State<_WidgetsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppMotion.instant,
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: AppMotion.enter),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        context.push(AppRoutes.widgets);
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (context, child) => Transform.scale(
          scale: _pressScale.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.colorScheme.primary.withAlpha(20),
                widget.colorScheme.tertiary.withAlpha(15),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.colorScheme.primary.withAlpha(30),
            ),
            // Subtle glow
            boxShadow: [
              BoxShadow(
                color: widget.colorScheme.primary.withAlpha(6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.colorScheme.primary,
                      widget.colorScheme.primary.withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  // Subtle shadow behind icon container
                  boxShadow: [
                    BoxShadow(
                      color: widget.colorScheme.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.layout_grid, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Phone Home Widgets',
                          style: widget.theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: widget.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Instant Scanner, Recent Docs, Tools & Vault widgets',
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevron_right, color: widget.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
