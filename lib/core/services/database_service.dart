import 'package:docora/core/services/logger_service.dart';
import 'package:docora/data/datasources/local/app_database.dart';

/// Singleton service that owns the Drift (SQLite) database instance.
/// Call [initialize] once at app startup in main() before runApp().
class DatabaseService {
  DatabaseService._();

  static AppDatabase? _instance;

  static AppDatabase get instance {
    assert(
      _instance != null,
      'DatabaseService.initialize() must be called before accessing instance.',
    );
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  /// Opens the Drift database. Safe to call multiple times — re-uses instance.
  static Future<void> initialize() async {
    if (_instance != null) {
      LoggerService.info('DatabaseService already initialized.');
      return;
    }
    try {
      _instance = AppDatabase();
      // Run a lightweight query to ensure the DB file opens correctly
      await _instance!.customSelect('SELECT 1').get();
      LoggerService.info('Drift database initialized successfully.');
    } catch (e, st) {
      LoggerService.error(
        'Failed to initialize database',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Closes the database — call only when the app is being destroyed.
  static Future<void> dispose() async {
    await _instance?.close();
    _instance = null;
  }
}
