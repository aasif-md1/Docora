import 'dart:io';
import 'package:docora/core/router/app_router.dart';
import 'package:docora/core/router/app_routes.dart';
import 'package:docora/core/services/intent_service.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Unified document opener that routes any file to its proper native in-app viewer.
/// Eliminates external app selection dialogs and ensures robust format dispatching.
class DocumentOpener {
  const DocumentOpener._();

  static const Set<String> pdfExtensions = {'pdf'};
  static const Set<String> wordExtensions = {'doc', 'docx', 'rtf', 'odt'};
  static const Set<String> excelExtensions = {'xls', 'xlsx', 'csv', 'tsv', 'ods'};
  static const Set<String> pptExtensions = {'ppt', 'pptx', 'odp'};
  static const Set<String> epubExtensions = {'epub', 'mobi'};
  static const Set<String> imageExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'heic'
  };
  static const Set<String> archiveExtensions = {'zip', 'rar', '7z', 'tar', 'gz'};
  static const Set<String> textExtensions = {
    'txt', 'md', 'markdown', 'log', 'json', 'xml', 'yaml', 'yml',
    'dart', 'py', 'js', 'ts', 'html', 'css', 'java', 'kt', 'cpp', 'c',
    'sh', 'sql', 'ini', 'conf', 'gradle', 'properties', 'env', 'toml'
  };

  static String? _lastOpenedPath;
  static DateTime? _lastOpenedTime;

  /// Dispatches a file path to the appropriate in-app viewer screen.
  /// Accepts either (BuildContext context, String filePath) or (String filePath).
  static void open(dynamic arg1, [dynamic arg2]) {
    String filePath = '';
    BuildContext? context;

    if (arg1 is BuildContext) {
      context = arg1;
      filePath = arg2 as String? ?? '';
    } else if (arg1 is String) {
      filePath = arg1;
      if (arg2 is BuildContext) {
        context = arg2;
      }
    }

    if (filePath.isEmpty) return;

    // Handle content:// URIs by resolving via native helper first
    if (filePath.startsWith('content://')) {
      IntentService.resolveContentUri(filePath).then((resolved) {
        if (resolved != null && resolved.isNotEmpty) {
          open(context, resolved);
        }
      });
      return;
    }

    // Strip and normalize file:// URI prefix if present
    if (filePath.startsWith('file://')) {
      try {
        filePath = Uri.parse(filePath).toFilePath();
      } catch (_) {
        filePath = filePath.replaceFirst('file://', '');
      }
    }

    // URL decode if percent-encoded
    if (filePath.contains('%')) {
      try {
        filePath = Uri.decodeFull(filePath);
      } catch (_) {}
    }

    final normalizedPath = p.normalize(filePath).toLowerCase();
    final now = DateTime.now();
    if (_lastOpenedPath == normalizedPath &&
        _lastOpenedTime != null &&
        now.difference(_lastOpenedTime!).inMilliseconds < 2000) {
      LoggerService.info('Ignoring duplicate document open request for: $filePath');
      return;
    }
    _lastOpenedPath = normalizedPath;
    _lastOpenedTime = now;

    // Persist for home screen widgets dynamically
    try {
      final docName = p.basename(filePath);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('widget_last_doc_title', docName);
        prefs.setString('widget_last_doc_path', filePath);
      });
    } catch (_) {}

    BuildContext? targetContext;
    if (context != null && context.mounted) {
      try {
        GoRouter.of(context);
        targetContext = context;
      } catch (_) {
        targetContext = rootNavigatorKey.currentContext;
      }
    } else {
      targetContext = rootNavigatorKey.currentContext;
    }

    if (targetContext == null) {
      LoggerService.warning('Cannot open document immediately: no valid context found, scheduling retry...');
      Future.delayed(const Duration(milliseconds: 300), () {
        final retryContext = rootNavigatorKey.currentContext;
        if (retryContext != null) {
          open(retryContext, filePath);
        }
      });
      return;
    }

    final ext = p.extension(filePath).replaceAll('.', '').toLowerCase().trim();
    final fileName = p.basename(filePath).toLowerCase();
    LoggerService.info('Opening document with extension: .$ext (filename: $fileName) at $filePath');

    final route = switch (ext) {
      _ when pdfExtensions.contains(ext) => AppRoutes.pdfViewer,
      _ when wordExtensions.contains(ext) => AppRoutes.wordViewer,
      _ when excelExtensions.contains(ext) => AppRoutes.excelViewer,
      _ when pptExtensions.contains(ext) => AppRoutes.pptViewer,
      _ when epubExtensions.contains(ext) => AppRoutes.epubViewer,
      _ when imageExtensions.contains(ext) => AppRoutes.imageViewer,
      _ when archiveExtensions.contains(ext) => AppRoutes.archiveViewer,
      _ when textExtensions.contains(ext) ||
             fileName == 'readme' || fileName.startsWith('readme.') ||
             fileName == 'license' || fileName == 'changelog' ||
             fileName == 'dockerfile' || fileName == 'makefile' =>
        AppRoutes.textViewer,
      _ => null,
    };

    if (route != null) {
      try {
        final router = GoRouter.of(targetContext);
        final currentUri = router.routeInformationProvider.value.uri.toString();
        // Prevent pushing duplicate screen if already viewing this document
        if (currentUri.contains(route) &&
            (currentUri.contains(Uri.encodeComponent(filePath)) ||
             currentUri.contains(p.basename(filePath)))) {
          LoggerService.info('Already viewing $filePath on top of stack, ignoring redundant push');
          return;
        }

        targetContext.push('$route?path=${Uri.encodeComponent(filePath)}', extra: filePath);
      } catch (e) {
        LoggerService.warning('Failed to push with targetContext: $e, trying root context');
        rootNavigatorKey.currentContext?.push(
          '$route?path=${Uri.encodeComponent(filePath)}',
          extra: filePath,
        );
      }
      return;
    }

    // Check if file is small enough to attempt text viewer before external app
    try {
      final file = File(filePath);
      if (file.existsSync() && file.lengthSync() < 2 * 1024 * 1024) {
        targetContext.push('${AppRoutes.textViewer}?path=${Uri.encodeComponent(filePath)}', extra: filePath);
        return;
      }
    } catch (_) {}

    // External app fallback only for truly binary unknown formats
    OpenFile.open(filePath);
  }
}
