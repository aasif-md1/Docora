import 'package:logger/logger.dart';

/// Centralized logging service.
/// In debug mode — logs to console with colors and stack traces.
/// In release mode — all logging is a no-op (zero overhead).
class LoggerService {
  LoggerService._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      lineLength: 100,
      printEmojis: false, // No emoji — consistent with global design rule
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  static void debug(String message, [Object? error]) =>
      _logger.d(message, error: error);

  static void info(String message, [Object? error]) =>
      _logger.i(message, error: error);

  static void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  static void wtf(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
