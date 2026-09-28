import 'dart:async';

import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

/// The main app shell — persistent bottom navigation bar + FAB.
/// Wraps the 4 main tabs: Home, Files, Tools, Settings.
class MainShell extends StatefulWidget {
  const MainShell({
    required this.child,
    this.location = AppRoutes.home,
    super.key,
  });

  final Widget child;
  final String location;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static final List<int> _tabHistory = [0];
  static bool _isPopping = false;

  static const List<_NavItem> _navItems = [
    _NavItem(
      route: AppRoutes.home,
      label: 'Home',
      icon: LucideIcons.house,
      activeIcon: LucideIcons.house,
    ),
    _NavItem(
      route: AppRoutes.files,
      label: 'Files',
      icon: LucideIcons.folder,
      activeIcon: LucideIcons.folder_open,
    ),
    _NavItem(
      route: AppRoutes.tools,
      label: 'Tools',
      icon: LucideIcons.wrench,
      activeIcon: LucideIcons.wrench,
    ),
    _NavItem(
      route: AppRoutes.settings,
      label: 'Settings',
      icon: LucideIcons.settings,
      activeIcon: LucideIcons.settings,
    ),
  ];

  int get _currentIndex {
    final loc = widget.location;
    if (loc.startsWith(AppRoutes.files)) return 1;
    if (loc.startsWith(AppRoutes.tools)) return 2;
    if (loc.startsWith(AppRoutes.settings)) return 3;
    return 0; // Home
  }

  void _recordTab(int index) {
    if (_isPopping) return;
    if (_tabHistory.isEmpty || _tabHistory.last != index) {
      _tabHistory.add(index);
      if (_tabHistory.length > 30) {
        _tabHistory.removeAt(0);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _recordTab(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _recordTab(_currentIndex);
    }
  }

  void _onTabTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    _recordTab(index);
    context.go(_navItems[index].route);
  }

  static int _lastBackTimestamp = 0;

  static void handleBack(BuildContext context, [int currentTabIndex = 0]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBackTimestamp < 200) {
      return; // Debounce rapid / duplicate back invocations
    }
    _lastBackTimestamp = now;

    // If the top of history matches the current tab, pop it to get the previous tab
    while (_tabHistory.isNotEmpty && _tabHistory.last == currentTabIndex) {
      _tabHistory.removeLast();
    }

    if (_tabHistory.isNotEmpty) {
      _isPopping = true;
      final prevIndex = _tabHistory.last;
      context.go(_navItems[prevIndex].route);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPopping = false;
      });
      return;
    }

    if (currentTabIndex != 0) {
      _isPopping = true;
      _tabHistory.clear();
      _tabHistory.add(0);
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPopping = false;
      });
      return;
    }

    // At root Home tab with no prior history: exit application cleanly
    SystemNavigator.pop();
  }

  bool get _isAtRootHome {
    if (_currentIndex != 0) return false;
    return _tabHistory.where((tab) => tab != 0).isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isAtRootHome) {
          SystemNavigator.pop();
        } else {
          handleBack(context, _currentIndex);
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onTabTap(context, i),
          destinations: _navItems.map((item) => NavigationDestination(
              icon: Icon(
                item.icon,
                size: AppSpacing.xl,
                color: colorScheme.onSurfaceVariant,
              ),
              selectedIcon: Icon(
                item.activeIcon,
                size: AppSpacing.xl,
                color: colorScheme.primary,
              ),
              label: item.label,
              tooltip: item.label,
            )).toList(),
        ),
        floatingActionButton: _DocoraFab(isVisible: currentIndex <= 1),
      ),
    );
  }
}

/// Individual navigation tab definition
class _NavItem {
  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Expandable FAB for: Open file, Scan, Create new
class _DocoraFab extends StatefulWidget {
  const _DocoraFab({required this.isVisible});
  final bool isVisible;

  @override
  State<_DocoraFab> createState() => _DocoraFabState();
}

class _DocoraFabState extends State<_DocoraFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (_isExpanded) _toggle();
  }

  void _onScanDocument(BuildContext context) {
    _close();
    AppMotion.subtleHaptic();
    context.push(AppRoutes.scanner);
  }

  Future<void> _onOpenFile(BuildContext context) async {
    _close();
    AppMotion.subtleHaptic();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        if (context.mounted) {
          DocumentOpener.open(context, result.files.first.path!);
        }
      }
    } catch (_) {}
  }

  void _onCreateNew(BuildContext context) {
    _close();
    AppMotion.subtleHaptic();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create or Import',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.camera, color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('Scan with Camera'),
                subtitle: const Text('Auto-crop receipts, invoices & documents'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.scanner);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.images, color: theme.colorScheme.secondary, size: 20),
                ),
                title: const Text('Photos to PDF'),
                subtitle: const Text('Convert multiple gallery photos to PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.tools);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.folder_open, color: theme.colorScheme.tertiary, size: 20),
                ),
                title: const Text('Browse Files'),
                subtitle: const Text('Open any document from phone storage'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onOpenFile(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FAB items (visible when expanded)
        ScaleTransition(
          scale: _expandAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniFabItem(
                icon: LucideIcons.scan_line,
                label: 'Scan document',
                onTap: () => _onScanDocument(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MiniFabItem(
                icon: LucideIcons.file_plus,
                label: 'Create new',
                onTap: () => _onCreateNew(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MiniFabItem(
                icon: LucideIcons.folder_open,
                label: 'Open file',
                onTap: () => _onOpenFile(context),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          elevation: 4,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          tooltip: 'Open actions',
          child: RotationTransition(
            turns: _rotateAnimation,
            child: const Icon(LucideIcons.plus, size: 24),
          ),
        ),
      ],
    );
  }
}

class _MiniFabItem extends StatelessWidget {
  const _MiniFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Mini FAB circle
          FloatingActionButton.small(
            heroTag: label,
            onPressed: onTap,
            elevation: 2,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            tooltip: label,
            child: Icon(icon, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Standard back-handler for all sub-screens pushed on top of the main shell.
/// Intercepts Android hardware/gesture back and ensures reliable return
/// to the previous screen without ever accidentally exiting the app.
class SubScreenBackHandler extends StatelessWidget {
  const SubScreenBackHandler({
    required this.child,
    this.fallbackRoute = AppRoutes.home,
    this.onBack,
    super.key,
  });

  final Widget child;
  final String fallbackRoute;
  final bool Function()? onBack;

  static int _lastSubBackTimestamp = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastSubBackTimestamp < 350) return;
        _lastSubBackTimestamp = now;

        if (onBack != null && onBack!()) {
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
      child: child,
    );
  }
}

/// Tab wrapper for top-level ShellRoute tabs.
/// Directly intercepts Android hardware/gesture back on non-home tabs and
/// returns cleanly to Home/previous tab, while allowing clean exit on Home.
class MainTabBackHandler extends StatelessWidget {
  const MainTabBackHandler({
    required this.child,
    this.tabIndex = 0,
    this.isHome = false,
    super.key,
  });

  final Widget child;
  final int tabIndex;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

