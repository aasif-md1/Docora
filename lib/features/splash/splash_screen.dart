import 'package:docora/core/router/app_router.dart';
import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/intent_service.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kOnboardingDoneKey = 'onboarding_done';

/// Fast, seamless splash screen that initializes intent consumption,
/// checks user startup preference (Home vs Files Browser), removes the
/// native splash screen, and routes directly without duplicate logo delay.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Check if app was launched via file intent (Open With...)
    final initialPath =
        await ref.read(intentServiceProvider).getAndConsumeInitialFile();
    if (!mounted) return;

    if (initialPath != null && initialPath.isNotEmpty) {
      LoggerService.info('Routing to opened document: $initialPath');
      FlutterNativeSplash.remove();
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
      FlutterNativeSplash.remove();
      context.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rootNavigatorKey.currentContext?.push(initialRoute);
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_kOnboardingDoneKey) ?? false;

    if (!mounted) return;

    FlutterNativeSplash.remove();

    if (onboardingDone) {
      final startup = prefs.getString('pref_startup_screen') ?? 'home';
      if (startup == 'files') {
        context.go(AppRoutes.files);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const SizedBox.shrink(),
    );
  }
}
