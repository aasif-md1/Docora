import 'dart:io';

import 'package:docora/core/services/logger_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ── Table Definitions ────────────────────────────────────────────────────────

/// Documents table — stores file metadata for all indexed documents
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  TextColumn get name => text()();
  TextColumn get extension => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get lastModified => dateTime()();
  DateTimeColumn get lastOpened => dateTime().nullable()();
  IntColumn get openCount => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON list
  IntColumn get pageCount => integer().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get category => text()();
  TextColumn get author => text().nullable()();
  TextColumn get title => text().nullable()();
}

/// Bookmarks table
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(Documents, #id)();
  TextColumn get documentPath => text()();
  IntColumn get pageIndex => integer().nullable()();
  RealColumn get scrollPosition => real().nullable()();
  TextColumn get label => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Collections table
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get colorHex => text()();
  TextColumn get documentPaths => text().withDefault(const Constant('[]'))(); // JSON list
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Recycle bin table
class RecycleBinEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get originalPath => text()();
  TextColumn get fileName => text()();
  TextColumn get category => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get deletedAt => dateTime()();
  DateTimeColumn get purgeAt => dateTime()();
}

/// Reading progress table
class ReadingProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get documentPath => text().unique()();
  IntColumn get lastPageIndex => integer().nullable()();
  RealColumn get scrollOffset => real().nullable()();
  IntColumn get totalPages => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Search history table
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text().unique()();
  DateTimeColumn get searchedAt => dateTime()();
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Documents,
  Bookmarks,
  Collections,
  RecycleBinEntries,
  ReadingProgress,
  SearchHistory,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ── Documents ──────────────────────────────────────────────────────────────

  Stream<List<Document>> watchRecentDocuments({int limit = 20}) =>
      (select(documents)
            ..where((d) => d.isDeleted.equals(false))
            ..orderBy([(d) => OrderingTerm.desc(d.lastOpened)])
            ..limit(limit))
          .watch();

  Stream<List<Document>> watchFavoriteDocuments() =>
      (select(documents)
            ..where((d) => d.isFavorite.equals(true) & d.isDeleted.equals(false))
            ..orderBy([(d) => OrderingTerm.desc(d.lastOpened)]))
          .watch();

  Stream<List<Document>> watchDocumentsByCategory(String category) =>
      (select(documents)
            ..where((d) =>
                d.category.equals(category) & d.isDeleted.equals(false))
            ..orderBy([(d) => OrderingTerm.desc(d.lastModified)]))
          .watch();

  Future<Document?> getDocumentByPath(String path) =>
      (select(documents)..where((d) => d.path.equals(path))).getSingleOrNull();

  Future<int> upsertDocument(DocumentsCompanion doc) =>
      into(documents).insertOnConflictUpdate(doc);

  Future<void> toggleFavorite(int id, {required bool value}) =>
      (update(documents)..where((d) => d.id.equals(id)))
          .write(DocumentsCompanion(isFavorite: Value(value)));

  Future<void> markOpened(int id) =>
      (update(documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(
          lastOpened: Value(DateTime.now()),
        ),
      );

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Stream<List<Bookmark>> watchBookmarksForDocument(int documentId) =>
      (select(bookmarks)
            ..where((b) => b.documentId.equals(documentId))
            ..orderBy([(b) => OrderingTerm.asc(b.pageIndex)]))
          .watch();

  Future<int> addBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(bookmark);

  Future<int> deleteBookmark(int id) =>
      (delete(bookmarks)..where((b) => b.id.equals(id))).go();

  // ── Reading Progress ───────────────────────────────────────────────────────

  Future<ReadingProgressData?> getProgress(String docPath) =>
      (select(readingProgress)
            ..where((r) => r.documentPath.equals(docPath)))
          .getSingleOrNull();

  Future<void> saveProgress(ReadingProgressCompanion progress) =>
      into(readingProgress).insert(
        progress,
        onConflict: DoUpdate(
          (old) => progress,
          target: [readingProgress.documentPath],
        ),
      );

  // ── Search History ─────────────────────────────────────────────────────────

  Stream<List<SearchHistoryData>> watchSearchHistory({int limit = 10}) =>
      (select(searchHistory)
            ..orderBy([(s) => OrderingTerm.desc(s.searchedAt)])
            ..limit(limit))
          .watch();

  Future<void> addSearchQuery(String query) => into(searchHistory).insert(
        SearchHistoryCompanion.insert(
          query: query,
          searchedAt: DateTime.now(),
        ),
        onConflict: DoUpdate(
          (old) => SearchHistoryCompanion.insert(
            query: query,
            searchedAt: DateTime.now(),
          ),
          target: [searchHistory.query],
        ),
      );

  Future<int> clearSearchHistory() => delete(searchHistory).go();

  // ── Recycle Bin ────────────────────────────────────────────────────────────

  Stream<List<RecycleBinEntry>> watchRecycleBin() =>
      (select(recycleBinEntries)
            ..orderBy([(r) => OrderingTerm.desc(r.deletedAt)]))
          .watch();

  Future<void> addToRecycleBin(RecycleBinEntriesCompanion entry) =>
      into(recycleBinEntries).insert(entry);

  Future<int> restoreFromRecycleBin(int id) =>
      (delete(recycleBinEntries)..where((r) => r.id.equals(id))).go();

  /// Permanently delete entries past their purgeAt date
  Future<int> purgExpiredRecycleBinEntries() =>
      (delete(recycleBinEntries)
            ..where((r) => r.purgeAt.isSmallerThanValue(DateTime.now())))
          .go();
}

/// Opens a connection to the SQLite database file
LazyDatabase _openConnection() => LazyDatabase(() async {
      final dbDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbDir.path, 'docora.sqlite'));
      LoggerService.info('Drift database at: ${file.path}');
      return NativeDatabase.createInBackground(file);
    });
