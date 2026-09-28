import 'package:docora/core/router/app_routes.dart';
import 'package:docora/features/collections/presentation/collections_screen.dart';
import 'package:docora/core/widgets/main_shell.dart';
import 'package:docora/features/dev/component_gallery_screen.dart';
import 'package:docora/features/files/presentation/files_screen.dart';
import 'package:docora/features/home/presentation/home_screen.dart';
import 'package:docora/features/onboarding/onboarding_screen.dart';
import 'package:docora/features/search/presentation/search_screen.dart';
import 'package:docora/features/settings/presentation/settings_screen.dart';
import 'package:docora/features/splash/splash_screen.dart';
import 'package:docora/features/files/presentation/recycle_bin_screen.dart';
import 'package:docora/features/scanner/presentation/scanner_screen.dart';
import 'package:docora/features/tools/presentation/tools_screen.dart';
import 'package:docora/features/tools/presentation/image_to_pdf_screen.dart';
import 'package:docora/features/tools/presentation/merge_pdf_screen.dart';
import 'package:docora/features/tools/presentation/split_pdf_screen.dart';
import 'package:docora/features/tools/presentation/watermark_screen.dart';
import 'package:docora/features/tools/presentation/compress_pdf_screen.dart';
import 'package:docora/features/vault/presentation/vault_screen.dart';
import 'package:docora/features/viewer/presentation/archive_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/epub_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/image_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/pdf_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/presentation_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/spreadsheet_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/text_viewer_screen.dart';
import 'package:docora/features/viewer/presentation/word_viewer_screen.dart';
import 'package:docora/features/widgets/presentation/widgets_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/logger_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Riverpod provider for the GoRouter instance.
/// The router is created once and shared across the app.
final appRouterProvider = Provider<GoRouter>((ref) => GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) {
      final loc = state.uri.toString();
      LoggerService.warning('GoRouter unhandled route error: $loc');
      final path = state.uri.isScheme('file') ? state.uri.toFilePath() : loc;
      if (path.isNotEmpty && (path.contains('/') || path.contains('\\'))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DocumentOpener.open(path);
        });
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    },
    redirect: (context, state) => null,
    routes: [
      // Splash — first screen, no shell
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding — shown only on first launch
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.matchedLocation.isNotEmpty ? state.matchedLocation : state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MainTabBackHandler(
                tabIndex: 0,
                isHome: true,
                child: HomeScreen(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.files,
            name: 'files',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MainTabBackHandler(
                tabIndex: 1,
                isHome: false,
                child: FilesScreen(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.tools,
            name: 'tools',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MainTabBackHandler(
                tabIndex: 2,
                isHome: false,
                child: ToolsScreen(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MainTabBackHandler(
                tabIndex: 3,
                isHome: false,
                child: SettingsScreen(),
              ),
            ),
          ),
        ],
      ),

      // Global search
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.home,
          child: SearchScreen(),
        ),
      ),

      // Developer Component Gallery
      GoRoute(
        path: AppRoutes.componentGallery,
        name: 'component_gallery',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.settings,
          child: ComponentGalleryScreen(),
        ),
      ),

      // In-app PDF Viewer
      GoRoute(
        path: AppRoutes.pdfViewer,
        name: 'pdf_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return PdfViewerScreen(filePath: path);
        },
      ),

      // In-app Word Document Viewer
      GoRoute(
        path: AppRoutes.wordViewer,
        name: 'word_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return WordViewerScreen(filePath: path);
        },
      ),

      // In-app Excel & CSV Spreadsheet Viewer
      GoRoute(
        path: AppRoutes.excelViewer,
        name: 'excel_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return SpreadsheetViewerScreen(filePath: path);
        },
      ),

      // In-app PowerPoint Presentation Viewer
      GoRoute(
        path: AppRoutes.pptViewer,
        name: 'ppt_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return PresentationViewerScreen(filePath: path);
        },
      ),

      // In-app Plain Text, Markdown & Code Viewer
      GoRoute(
        path: AppRoutes.textViewer,
        name: 'text_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return TextViewerScreen(filePath: path);
        },
      ),

      // In-app EPUB E-Book Reader
      GoRoute(
        path: AppRoutes.epubViewer,
        name: 'epub_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return SubScreenBackHandler(
            fallbackRoute: AppRoutes.files,
            child: EpubViewerScreen(filePath: path),
          );
        },
      ),

      // In-app Image Viewer
      GoRoute(
        path: AppRoutes.imageViewer,
        name: 'image_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return SubScreenBackHandler(
            fallbackRoute: AppRoutes.files,
            child: ImageViewerScreen(filePath: path),
          );
        },
      ),

      // In-app Archive Viewer
      GoRoute(
        path: AppRoutes.archiveViewer,
        name: 'archive_viewer',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'] ??
              '';
          return SubScreenBackHandler(
            fallbackRoute: AppRoutes.files,
            child: ArchiveViewerScreen(filePath: path),
          );
        },
      ),

      // Document Scanner
      GoRoute(
        path: AppRoutes.scanner,
        name: 'scanner',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: ScannerScreen(),
        ),
      ),

      // Private Vault
      GoRoute(
        path: AppRoutes.vault,
        name: 'vault',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: VaultScreen(),
        ),
      ),

      // Recycle Bin
      GoRoute(
        path: AppRoutes.recycleBin,
        name: 'recycle_bin',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: RecycleBinScreen(),
        ),
      ),

      // Collections
      GoRoute(
        path: AppRoutes.collections,
        name: 'collections',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: CollectionsScreen(),
        ),
      ),

      // Widgets Gallery
      GoRoute(
        path: AppRoutes.widgets,
        name: 'widgets',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.home,
          child: WidgetsGalleryScreen(),
        ),
      ),

      // Tool 1: Image to PDF
      GoRoute(
        path: AppRoutes.imageToPdf,
        name: 'image_to_pdf',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: ImageToPdfScreen(),
        ),
      ),

      // Tool 2: Merge PDF
      GoRoute(
        path: AppRoutes.mergePdf,
        name: 'merge_pdf',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: MergePdfScreen(),
        ),
      ),

      // Tool 2b: Split PDF
      GoRoute(
        path: AppRoutes.splitPdf,
        name: 'split_pdf',
        builder: (context, state) {
          final path = state.extra as String? ??
              state.uri.queryParameters['path'];
          return SubScreenBackHandler(
            fallbackRoute: AppRoutes.tools,
            child: SplitPdfScreen(initialFilePath: path),
          );
        },
      ),

      // Tool 3: Watermark PDF
      GoRoute(
        path: AppRoutes.watermarkPdf,
        name: 'watermark_pdf',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: WatermarkScreen(),
        ),
      ),

      // Tool 4: Compress PDF
      GoRoute(
        path: AppRoutes.compressPdf,
        name: 'compress_pdf',
        builder: (context, state) => const SubScreenBackHandler(
          fallbackRoute: AppRoutes.tools,
          child: CompressPdfScreen(),
        ),
      ),
    ],
  ));

/// Shown when navigation fails or a route is not found
class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen({required this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'An unknown navigation error occurred.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
}
