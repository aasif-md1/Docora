import 'dart:convert';
import 'package:docora/core/services/database_service.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/data/datasources/local/app_database.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/features/files/presentation/providers/files_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model for a document collection
class DocumentCollection {
  const DocumentCollection({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.documentPaths,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String colorHex;
  final List<String> documentPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get documentCount => documentPaths.length;
}

/// Provider for all collections as a reactive stream
final collectionsStreamProvider =
    StreamProvider.autoDispose<List<DocumentCollection>>((ref) {
  final db = DatabaseService.instance;
  return (db.select(db.collections)
        ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
      .watch()
      .map((rows) => rows.map(_toCollection).toList());
});

/// Provider for a single collection's documents
final collectionDocumentsProvider = FutureProvider.autoDispose
    .family<List<DocumentEntity>, int>((ref, collectionId) async {
  final db = DatabaseService.instance;
  final row = await (db.select(db.collections)
        ..where((c) => c.id.equals(collectionId)))
      .getSingleOrNull();

  if (row == null) return [];

  final paths = _decodePaths(row.documentPaths);
  if (paths.isEmpty) return [];

  final repo = ref.read(documentRepositoryProvider);
  final results = <DocumentEntity>[];
  for (final path in paths) {
    final doc = await repo.getDocumentByPath(path);
    if (doc != null) results.add(doc);
  }
  return results;
});

/// Controller for collection CRUD operations
final collectionsControllerProvider =
    AsyncNotifierProvider<CollectionsController, void>(
        CollectionsController.new);

class CollectionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AppDatabase get _db => DatabaseService.instance;

  /// Create a new collection
  Future<int> createCollection({
    required String name,
    required String colorHex,
  }) async {
    final now = DateTime.now();
    final id = await _db.into(_db.collections).insert(
          CollectionsCompanion.insert(
            name: name,
            colorHex: colorHex,
            createdAt: now,
            updatedAt: now,
          ),
        );
    LoggerService.info('Created collection "$name" with id=$id');
    return id;
  }

  /// Add a document path to a collection
  Future<void> addDocumentToCollection({
    required int collectionId,
    required String documentPath,
  }) async {
    final row = await ((_db.select(_db.collections))
          ..where((c) => c.id.equals(collectionId)))
        .getSingleOrNull();
    if (row == null) return;

    final paths = _decodePaths(row.documentPaths);
    if (!paths.contains(documentPath)) {
      paths.add(documentPath);
    }

    await (_db.update(_db.collections)
          ..where((c) => c.id.equals(collectionId)))
        .write(CollectionsCompanion(
      documentPaths: Value(jsonEncode(paths)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Remove a document path from a collection
  Future<void> removeDocumentFromCollection({
    required int collectionId,
    required String documentPath,
  }) async {
    final row = await ((_db.select(_db.collections))
          ..where((c) => c.id.equals(collectionId)))
        .getSingleOrNull();
    if (row == null) return;

    final paths = _decodePaths(row.documentPaths);
    paths.remove(documentPath);

    await (_db.update(_db.collections)
          ..where((c) => c.id.equals(collectionId)))
        .write(CollectionsCompanion(
      documentPaths: Value(jsonEncode(paths)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete a collection entirely
  Future<void> deleteCollection(int id) async {
    await (_db.delete(_db.collections)..where((c) => c.id.equals(id))).go();
    LoggerService.info('Deleted collection id=$id');
  }

  /// Rename a collection
  Future<void> renameCollection(int id, String newName) async {
    await (_db.update(_db.collections)..where((c) => c.id.equals(id))).write(
      CollectionsCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

DocumentCollection _toCollection(Collection row) {
  return DocumentCollection(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    documentPaths: _decodePaths(row.documentPaths),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

List<String> _decodePaths(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
  } on Object catch (_) {}
  return [];
}
