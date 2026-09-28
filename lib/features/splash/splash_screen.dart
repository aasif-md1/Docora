import 'package:docora/core/router/app_router.dart';
import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/intent_service.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kOnboardingDoneKey = 'onboarding_done';

/// Splash screen that waits for initialization, then routes to
/// onboarding (first launch) or home (returning user).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppMotion.slow,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Allow the logo animation to play
    await Future<void>.delayed(AppMotion.slow + AppMotion.normal);


    if (!mounted) return;

    // Check if app was launched via file intent (Open With...)
    final initialPath =
        await ref.read(intentServiceProvider).getAndConsumeInitialFile();
    if (!mounted) return;

    if (initialPath != null && initialPath.isNotEmpty) {
      LoggerService.info('Routing to opened document: $initialPath');
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DocumentOpener.open(rootNavigatorKey.currentContext ?? context, initialPath);
      });
      return;
    }

    // Check if app was launched via shortcut or widget route intent
    final initialRoute =
        await ref.read(intentServiceProvider).getAndConsumeInitialRoute();
    if (!mounted) return;

    if (initialRoute != null && initialRoute.isNotEmpty) {
      LoggerService.info('Routing to requested intent route: $initialRoute');
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rootNavigatorKey.currentContext?.push(initialRoute);
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_kOnboardingDoneKey) ?? false;

    if (!mounted) return;

    if (onboardingDone) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo placeholder — replaced with actual SVG in Phase 2
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Docora',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Every document. Beautifully simple.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
