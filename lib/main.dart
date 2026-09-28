import 'package:docora/core/errors/global_error_handler.dart';
import 'package:docora/core/router/app_router.dart';
import 'package:docora/core/services/database_service.dart';
import 'package:docora/core/services/intent_service.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/app_theme.dart';
import 'package:docora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global Flutter error handling before anything else
  GlobalErrorHandler.initialize();

  // Initialize Drift database
  await DatabaseService.initialize();

  LoggerService.info('Docora initialized — launching app.');

  runApp(
    const ProviderScope(
      child: DocoraApp(),
    ),
  );
}

class DocoraApp extends ConsumerStatefulWidget {
  const DocoraApp({super.key});

  @override
  ConsumerState<DocoraApp> createState() => _DocoraAppState();
}

class _DocoraAppState extends ConsumerState<DocoraApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(intentServiceProvider).initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appTheme = ref.watch(appThemeProvider);

    ref.read(intentServiceProvider).updateContext(context);

    return MaterialApp.router(
      title: 'Docora',
      debugShowCheckedModeBanner: false,
      theme: appTheme.light,
      darkTheme: appTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
