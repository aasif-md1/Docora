import 'dart:convert';
import 'dart:io';

import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/data/datasources/local/app_database.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/domain/repositories/document_repository.dart';
import 'package:drift/drift.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete implementation of [DocumentRepository] backed by Drift SQLite database
/// and physical filesystem file operations.
class DocumentRepositoryImpl implements DocumentRepository {
  const DocumentRepositoryImpl(this._db);

  final AppDatabase _db;

  DocumentEntity _toEntity(Document row) {
    List<String> tags = [];
    try {
      final decoded = jsonDecode(row.tags);
      if (decoded is List) {
        tags = decoded.map((e) => e.toString()).toList();
      }
    } on Object catch (_) {
      tags = [];
    }

    return DocumentEntity(
      id: row.id,
      path: row.path,
      name: row.name,
      extension: row.extension,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      lastModified: row.lastModified,
      lastOpened: row.lastOpened,
      openCount: row.openCount,
      isFavorite: row.isFavorite,
      isDeleted: row.isDeleted,
      tags: tags,
      pageCount: row.pageCount,
      thumbnailPath: row.thumbnailPath,
      category: row.category,
      author: row.author,
      title: row.title,
    );
  }

  DocumentsCompanion _toCompanion(DocumentEntity entity) =>
      DocumentsCompanion.insert(
        path: entity.path,
        name: entity.name,
        extension: entity.extension,
        mimeType: entity.mimeType,
        sizeBytes: entity.sizeBytes,
        lastModified: entity.lastModified,
        lastOpened: Value(entity.lastOpened),
        openCount: Value(entity.openCount),
        isFavorite: Value(entity.isFavorite),
        isDeleted: Value(entity.isDeleted),
        tags: Value(jsonEncode(entity.tags)),
        pageCount: Value(entity.pageCount),
        thumbnailPath: Value(entity.thumbnailPath),
        category: entity.category,
        author: Value(entity.author),
        title: Value(entity.title),
      );

  @override
  Stream<List<DocumentEntity>> watchDocuments({
    String? category,
    bool? isFavorite,
    String? query,
    DocumentSortOption sort = DocumentSortOption.dateModifiedDesc,
  }) {
    final queryBuilder = _db.select(_db.documents)
      ..where((d) {
        Expression<bool> predicate = d.isDeleted.equals(false);

        if (category != null &&
            category.toLowerCase() != 'all' &&
            category.trim().isNotEmpty) {
          predicate = predicate & d.category.equals(category.toLowerCase());
        }

        if (isFavorite == true) {
          predicate = predicate & d.isFavorite.equals(true);
        }

        if (query != null && query.trim().isNotEmpty) {
          final cleanQuery = '%${query.trim().toLowerCase()}%';
          predicate = predicate &
              (d.name.lower().like(cleanQuery) |
                  d.tags.lower().like(cleanQuery));
        }

        return predicate;
      });

    // Apply sorting
    switch (sort) {
      case DocumentSortOption.nameAsc:
        queryBuilder.orderBy([(d) => OrderingTerm.asc(d.name.lower())]);
      case DocumentSortOption.nameDesc:
        queryBuilder.orderBy([(d) => OrderingTerm.desc(d.name.lower())]);
      case DocumentSortOption.dateModifiedDesc:
        queryBuilder.orderBy([(d) => OrderingTerm.desc(d.lastModified)]);
      case DocumentSortOption.dateModifiedAsc:
        queryBuilder.orderBy([(d) => OrderingTerm.asc(d.lastModified)]);
      case DocumentSortOption.sizeDesc:
        queryBuilder.orderBy([(d) => OrderingTerm.desc(d.sizeBytes)]);
      case DocumentSortOption.sizeAsc:
        queryBuilder.orderBy([(d) => OrderingTerm.asc(d.sizeBytes)]);
    }

    return queryBuilder
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<DocumentEntity>> watchRecentDocuments({int limit = 10}) =>
      _db.watchRecentDocuments(limit: limit).map(
            (rows) => rows.map(_toEntity).toList(),
          );

  @override
  Stream<List<DocumentEntity>> watchFavoriteDocuments() =>
      _db.watchFavoriteDocuments().map(
            (rows) => rows.map(_toEntity).toList(),
          );

  @override
  Future<DocumentEntity?> getDocumentByPath(String path) async {
    final row = await _db.getDocumentByPath(path);
    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<void> upsertDocument(DocumentEntity document) async {
    await _db.upsertDocument(_toCompanion(document));
  }

  @override
  Future<void> upsertDocuments(List<DocumentEntity> documents) async {
    await _db.batch((batch) {
      for (final doc in documents) {
        batch.insert(
          _db.documents,
          _toCompanion(doc),
          onConflict: DoUpdate((old) => _toCompanion(doc)),
        );
      }
    });
  }

  @override
  Future<void> toggleFavorite(int id, {required bool isFavorite}) async {
    await _db.toggleFavorite(id, value: isFavorite);
  }

  @override
  Future<void> markOpened(int id) async {
    final now = DateTime.now();
    final row = await (_db.select(_db.documents)..where((d) => d.id.equals(id)))
        .getSingleOrNull();

    if (row != null) {
      await (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(
          lastOpened: Value(now),
          openCount: Value(row.openCount + 1),
        ),
      );
    }
  }

  @override
  Future<DocumentEntity> renameDocument(int id, String newName) async {
    final row = await (_db.select(_db.documents)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      throw FileSystemException('Document with id $id not found in database');
    }

    final oldFile = File(row.path);
    final dir = p.dirname(row.path);
    final ext = p.extension(newName).replaceAll('.', '').toLowerCase();
    final effectiveExt = ext.isNotEmpty ? ext : row.extension;
    final finalName = ext.isEmpty ? '$newName.${row.extension}' : newName;
    final newPath = p.join(dir, finalName);

    if (oldFile.existsSync()) {
      await oldFile.rename(newPath);
    }

    final format = DocumentFormat.fromExtension(effectiveExt);
    final mime = lookupMimeType(newPath) ?? row.mimeType;

    await (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(
        path: Value(newPath),
        name: Value(finalName),
        extension: Value(effectiveExt),
        mimeType: Value(mime),
        category: Value(format.name),
        lastModified: Value(DateTime.now()),
      ),
    );

    final updated = await (_db.select(_db.documents)
          ..where((d) => d.id.equals(id)))
        .getSingle();

    return _toEntity(updated);
  }

  @override
  Future<void> moveToRecycleBin(DocumentEntity doc) async {
    // 1. Mark document as deleted in Documents table
    await (_db.update(_db.documents)..where((d) => d.id.equals(doc.id))).write(
      const DocumentsCompanion(
        isDeleted: Value(true),
      ),
    );

    // 2. Add entry to RecycleBinEntries with 30-day purge threshold
    final now = DateTime.now();
    await _db.addToRecycleBin(
      RecycleBinEntriesCompanion.insert(
        originalPath: doc.path,
        fileName: doc.name,
        category: doc.category,
        sizeBytes: doc.sizeBytes,
        deletedAt: now,
        purgeAt: now.add(const Duration(days: 30)),
      ),
    );
    LoggerService.info('Moved document ${doc.name} to Recycle Bin');
  }

  @override
  Future<List<DocumentEntity>> getRecycleBinDocuments() async {
    final rows = await (_db.select(_db.documents)..where((d) => d.isDeleted.equals(true))).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> restoreFromRecycleBin(DocumentEntity doc) async {
    await (_db.update(_db.documents)..where((d) => d.id.equals(doc.id))).write(
      const DocumentsCompanion(
        isDeleted: Value(false),
      ),
    );
    LoggerService.info('Restored document ${doc.name} from Recycle Bin');
  }

  @override
  Future<void> permanentlyDeleteDocument(DocumentEntity doc) async {
    try {
      final file = File(doc.path);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (e, st) {
      LoggerService.error('Error physically deleting file: ${doc.path}',
          error: e, stackTrace: st);
    }

    await (_db.delete(_db.documents)..where((d) => d.id.equals(doc.id))).go();
    LoggerService.info('Permanently deleted document ${doc.name}');
  }

  @override
  Future<Map<String, int>> getCategoryCounts() async {
    final activeDocs = await (_db.select(_db.documents)
          ..where((d) => d.isDeleted.equals(false)))
        .get();

    final counts = <String, int>{
      'all': activeDocs.length,
    };

    for (final doc in activeDocs) {
      final cat = doc.category.toLowerCase();
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Future<int> getTotalStorageBytes() async {
    final activeDocs = await (_db.select(_db.documents)
          ..where((d) => d.isDeleted.equals(false)))
        .get();

    return activeDocs.fold<int>(0, (sum, d) => sum + d.sizeBytes);
  }

  @override
  Future<int?> getLastReadPage(String path) async {
    final progress = await _db.getProgress(path);
    return progress?.lastPageIndex;
  }

  @override
  Future<void> saveReadingProgress({
    required String path,
    required int pageIndex,
    required int totalPages,
    double? scrollOffset,
  }) async {
    await _db.saveProgress(
      ReadingProgressCompanion.insert(
        documentPath: path,
        lastPageIndex: Value(pageIndex),
        totalPages: Value(totalPages),
        scrollOffset: Value(scrollOffset),
        updatedAt: DateTime.now(),
      ),
    );

    // Sync to homescreen widgets
    try {
      final filename = p.basename(path);
      final percent = totalPages > 0 ? (((pageIndex + 1) / totalPages) * 100).round() : 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_last_doc_title', filename);
      await prefs.setInt('widget_last_doc_progress', percent);
      await prefs.setString('widget_last_doc_path', path);
    } catch (_) {}
  }

  @override
  Future<void> updateDocumentPageCount({
    required String path,
    required int pageCount,
  }) async {
    await (_db.update(_db.documents)..where((d) => d.path.equals(path))).write(
      DocumentsCompanion(pageCount: Value(pageCount)),
    );
  }
}
