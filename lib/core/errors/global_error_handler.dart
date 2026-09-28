import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Registers global Flutter and Dart zone error handlers.
/// Catches unhandled exceptions and logs them without crashing the app
/// in production — in debug mode they still propagate normally.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static void initialize() {
    // Catch Flutter framework errors (widget build errors, rendering errors)
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggerService.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Override release grey box so errors are readable and debuggable
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('DOCORA_ERROR: ${details.exception}\n${details.stack}');
      return Material(
        color: const Color(0xFF1E1E2E),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Document Rendering Notice',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${details.exceptionAsString()}\n\nStack:\n${details.stack}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };

    // Catch Dart async errors not caught by the Flutter framework
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      LoggerService.error(
        'Unhandled platform error',
        error: error,
        stackTrace: stack,
      );
      return true; // Returning true means "handled — do not crash"
    };
  }
}
