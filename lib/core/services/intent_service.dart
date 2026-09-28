import 'dart:async';
import 'package:docora/core/router/app_router.dart';
import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final intentServiceProvider = Provider<IntentService>((ref) => IntentService());

/// Holds any pending document path waiting to be opened once the UI shell is ready.
final pendingOpenDocumentProvider = StateProvider<String?>((ref) => null);

class IntentService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.docora.app/file_intent');
  static const EventChannel _eventChannel =
      EventChannel('com.docora.app/file_intent_stream');
  static const EventChannel _routeEventChannel =
      EventChannel('com.docora.app/route_intent_stream');

  StreamSubscription<dynamic>? _subscription;
  StreamSubscription<dynamic>? _routeSubscription;

  void initialize(BuildContext context) {
    _listenToIntentStream();
    _listenToRouteStream();
  }

  void updateContext(BuildContext context) {}

  /// Consumes the initial launch intent file if available
  Future<String?> getAndConsumeInitialFile() async {
    try {
      final String? path =
          await _methodChannel.invokeMethod<String>('getInitialFile');
      if (path != null && path.isNotEmpty) {
        LoggerService.info('Consumed initial intent file: $path');
        return path;
      }
      return null;
    } catch (e) {
      LoggerService.error('Error invoking getInitialFile: $e');
      return null;
    }
  }

  /// Consumes the initial launch route (from widget or shortcut) if available
  Future<String?> getAndConsumeInitialRoute() async {
    try {
      final String? route =
          await _methodChannel.invokeMethod<String>('getInitialRoute');
      if (route != null && route.isNotEmpty) {
        LoggerService.info('Consumed initial intent route: $route');
        return route;
      }
      return null;
    } catch (e) {
      LoggerService.error('Error invoking getInitialRoute: $e');
      return null;
    }
  }

  void _listenToIntentStream() {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic path) {
        if (path is String && path.isNotEmpty) {
          LoggerService.info('Received runtime intent file from stream: $path');
          DocumentOpener.open(path);
        }
      },
      onError: (dynamic error) {
        LoggerService.error('Error on intent stream: $error');
      },
    );
  }

  void _listenToRouteStream() {
    _routeSubscription?.cancel();
    _routeSubscription = _routeEventChannel.receiveBroadcastStream().listen(
      (dynamic route) {
        if (route is String && route.isNotEmpty) {
          LoggerService.info('Received runtime route from stream: $route');
          _navigateToRoute(route);
        }
      },
      onError: (dynamic error) {
        LoggerService.error('Error on route stream: $error');
      },
    );
  }

  static void _navigateToRoute(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          context.push(route);
        }
      } catch (e) {
        LoggerService.error('Failed to navigate to route $route: $e');
      }
    });
  }

  /// Helper to resolve any content:// URI into a local cache path
  static Future<String?> resolveContentUri(String uri) async {
    try {
      final String? resolved = await _methodChannel
          .invokeMethod<String>('resolveContentUri', {'uri': uri});
      return resolved;
    } on PlatformException catch (e) {
      LoggerService.error('Failed to resolve content uri: ${e.message}');
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _routeSubscription?.cancel();
  }
}
