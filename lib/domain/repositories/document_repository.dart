import 'package:docora/domain/entities/document_entity.dart';

/// Available sorting criteria for document lists
enum DocumentSortOption {
  dateModifiedDesc('Date (Newest)', isDescending: true),
  dateModifiedAsc('Date (Oldest)', isDescending: false),
  nameAsc('Name (A to Z)', isDescending: false),
  nameDesc('Name (Z to A)', isDescending: true),
  sizeDesc('Size (Largest)', isDescending: true),
  sizeAsc('Size (Smallest)', isDescending: false);

  const DocumentSortOption(this.label, {required this.isDescending});
  final String label;
  final bool isDescending;
}

/// Abstract contract for document storage operations and reactive streams.
abstract class DocumentRepository {
  /// Stream of all active documents matching optional category, favorite status, query, and sorting
  Stream<List<DocumentEntity>> watchDocuments({
    String? category,
    bool? isFavorite,
    String? query,
    DocumentSortOption sort = DocumentSortOption.dateModifiedDesc,
  });

  /// Stream of recently opened documents
  Stream<List<DocumentEntity>> watchRecentDocuments({int limit = 10});

  /// Stream of favorite documents
  Stream<List<DocumentEntity>> watchFavoriteDocuments();

  /// Retrieve a single document by absolute path
  Future<DocumentEntity?> getDocumentByPath(String path);

  /// Upsert a single document into index
  Future<void> upsertDocument(DocumentEntity document);

  /// Batch upsert scanned documents into index
  Future<void> upsertDocuments(List<DocumentEntity> documents);

  /// Toggle favorite status of a document
  Future<void> toggleFavorite(int id, {required bool isFavorite});

  /// Update last opened timestamp and increment open count
  Future<void> markOpened(int id);

  /// Rename a document file on disk and update the index
  Future<DocumentEntity> renameDocument(int id, String newName);

  /// Soft delete: mark document as deleted and record in RecycleBin
  Future<void> moveToRecycleBin(DocumentEntity doc);

  /// Restore document from recycle bin
  Future<void> restoreFromRecycleBin(DocumentEntity doc);

  /// Retrieve all documents currently in the recycle bin
  Future<List<DocumentEntity>> getRecycleBinDocuments();

  /// Permanently delete document from disk and database
  Future<void> permanentlyDeleteDocument(DocumentEntity doc);

  /// Get document counts grouped by category ('pdf', 'word', etc.)
  Future<Map<String, int>> getCategoryCounts();

  /// Get total disk space used by indexed documents in bytes
  Future<int> getTotalStorageBytes();

  /// Retrieve last read page index for a document path (1-based, or null if unread)
  Future<int?> getLastReadPage(String path);

  /// Save reading progress for a document
  Future<void> saveReadingProgress({
    required String path,
    required int pageIndex,
    required int totalPages,
    double? scrollOffset,
  });

  /// Update page count of a document in the index
  Future<void> updateDocumentPageCount({
    required String path,
    required int pageCount,
  });
}
