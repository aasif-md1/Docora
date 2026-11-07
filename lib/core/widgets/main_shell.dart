import 'dart:async';

import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_theme.dart';
import 'package:docora/widgets/docora_bottom_nav.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The main app shell — persistent bottom navigation bar + centre action button.
/// Wraps the 4 main tabs: Home, Files, Tools, Settings.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    required this.child,
    this.location = AppRoutes.home,
    super.key,
  });

  final Widget child;
  final String location;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static final List<int> _tabHistory = [0];
  static bool _isPopping = false;

  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.files,
    AppRoutes.tools,
    AppRoutes.settings,
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
    if (index == _currentIndex) return;
    _recordTab(index);
    context.go(_routes[index]);
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
      context.go(_routes[prevIndex]);
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

  Future<void> _onOpenFile(BuildContext context) async {
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

  void _onAddTap(BuildContext context, Color currentAccent) {
    AppMotion.subtleHaptic();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
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
                    color: currentAccent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.camera, color: currentAccent, size: 20),
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
                    color: colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.images, color: colorScheme.secondary, size: 20),
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
                    color: colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.folder_open, color: colorScheme.tertiary, size: 20),
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
    final currentIndex = _currentIndex;
    final accentIndex = ref.watch(accentColorIndexProvider);
    final currentAccent = AppColors.accentOptions[accentIndex.clamp(0, AppColors.accentOptions.length - 1)];

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
        bottomNavigationBar: DocoraBottomNav(
          currentIndex: currentIndex,
          accent: currentAccent,
          onTap: (i) => _onTabTap(context, i),
          onAddTap: () => _onAddTap(context, currentAccent),
        ),
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
