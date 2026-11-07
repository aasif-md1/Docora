import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/intent_service.dart';
import 'package:docora/core/services/storage_permission_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/widgets/widgets.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Minimalist, content-focused Home Dashboard screen.
/// Follows the Centralized Master Design System:
/// Neutral foundations, clear visual hierarchy, 8-pt spacing, and no rainbow clutter.
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _staggerAnimation(int index, {int total = 4}) {
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
    // Listen for incoming system document open requests
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_greeting()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            tooltip: 'Search documents',
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(LucideIcons.scan_line, size: 20),
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
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(filesControllerProvider.notifier).scanDeviceStorage();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: AppSpacing.md,
          ),
          children: [
            if (isScanning)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: LinearProgressIndicator(minHeight: 2.5),
              ),

            // Section 1: Storage Overview Hero Banner
            _StaggeredFadeSlide(
              animation: _staggerAnimation(0),
              child: DecoratedBox(
                decoration: ClayDecorations.card(
                  context,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          LucideIcons.hard_drive,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalDocs Documents Indexed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Using ${_formatBytes(totalBytes)} offline storage',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      DecoratedBox(
                        decoration: ClayDecorations.subtle(
                          context,
                          borderRadius: BorderRadius.circular(20),
                          accentColor: colorScheme.primary,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.go(AppRoutes.files),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View All',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.chevron_right,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionSpacing),

            // Section 2: Quick Format Categories
            _StaggeredFadeSlide(
              animation: _staggerAnimation(1),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'CATEGORIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            _StaggeredFadeSlide(
              animation: _staggerAnimation(1),
              child: Row(
                children: [
                  _CleanCategoryTile(
                    title: 'PDF',
                    count: counts['pdf'] ?? 0,
                    icon: LucideIcons.file_text,
                    onTap: () => _onCategoryTap(context, ref, 'pdf'),
                  ),
                  const SizedBox(width: 12),
                  _CleanCategoryTile(
                    title: 'Word',
                    count: counts['word'] ?? 0,
                    icon: LucideIcons.file_pen,
                    onTap: () => _onCategoryTap(context, ref, 'word'),
                  ),
                  const SizedBox(width: 12),
                  _CleanCategoryTile(
                    title: 'Excel',
                    count: counts['excel'] ?? 0,
                    icon: LucideIcons.file_spreadsheet,
                    onTap: () => _onCategoryTap(context, ref, 'excel'),
                  ),
                  const SizedBox(width: 12),
                  _CleanCategoryTile(
                    title: 'PPT',
                    count: counts['ppt'] ?? 0,
                    icon: LucideIcons.file_play,
                    onTap: () => _onCategoryTap(context, ref, 'ppt'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sectionSpacing),

            // Section 3: Recent Documents
            _StaggeredFadeSlide(
              animation: _staggerAnimation(2),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT DOCUMENTS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
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
              animation: _staggerAnimation(3),
              child: recentDocsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: DocumentListItemSkeleton(),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err'),
                ),
                data: (recentDocs) {
                  if (recentDocs.isEmpty) {
                    return DecoratedBox(
                      decoration: ClayDecorations.card(
                        context,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl,
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.file_text,
                              size: 40,
                              color: colorScheme.onSurfaceVariant.withAlpha(120),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No recent documents',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Documents you open will appear here for fast access.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                        AppMotion.subtleHaptic();
                        DocumentOpener.open(context, doc.path);
                      },
                    )).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxl * 2),
          ],
        ),
      ),
    );
  }
}

/// Refined category tile following the neutral design foundation.
class _CleanCategoryTile extends StatefulWidget {
  const _CleanCategoryTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CleanCategoryTile> createState() => _CleanCategoryTileState();
}

class _CleanCategoryTileState extends State<_CleanCategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: AppMotion.instant,
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _pressController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _pressController.reverse();
        },
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (context, child) => Transform.scale(
            scale: _pressScale.value,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 8,
            ),
            decoration: ClayDecorations.tile(
              context,
              borderRadius: BorderRadius.circular(16),
              isPressed: _isPressed,
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: colorScheme.primary),
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
                    color: colorScheme.onSurfaceVariant,
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
      builder: (context, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
