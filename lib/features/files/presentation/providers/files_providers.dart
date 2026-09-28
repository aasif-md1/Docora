import 'package:docora/core/services/database_service.dart';
import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/services/storage_permission_service.dart';
import 'package:docora/core/services/storage_scanner_service.dart';
import 'package:docora/data/repositories/document_repository_impl.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/domain/repositories/document_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Base Service & Repository Providers ─────────────────────────────────────

final documentRepositoryProvider = Provider<DocumentRepository>(
    (ref) => DocumentRepositoryImpl(DatabaseService.instance));

final storageScannerServiceProvider = Provider<StorageScannerService>(
    (ref) => const StorageScannerService());

final storagePermissionServiceProvider =
    Provider<StoragePermissionService>(
        (ref) => const StoragePermissionService());

final storagePermissionStateProvider =
    FutureProvider<StoragePermissionState>((ref) =>
        ref.watch(storagePermissionServiceProvider).checkPermission());

// ── UI Filter & State Providers ─────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

final documentSortProvider =
    StateProvider<DocumentSortOption>((ref) => DocumentSortOption.dateModifiedDesc);

final searchQueryProvider = StateProvider<String>((ref) => '');

final isGridViewProvider = StateProvider<bool>((ref) => false);

final isScanningProvider = StateProvider<bool>((ref) => false);

final isSelectionModeProvider = StateProvider<bool>((ref) => false);

final selectedDocumentIdsProvider = StateProvider<Set<int>>((ref) => {});

// ── Reactive Stream Providers ───────────────────────────────────────────────

/// Watches documents matching active filter, query, and sorting
final documentsStreamProvider =
    StreamProvider.autoDispose<List<DocumentEntity>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final sort = ref.watch(documentSortProvider);
  final query = ref.watch(searchQueryProvider);

  return repo.watchDocuments(
    category: category,
    sort: sort,
    query: query,
  );
});

/// Watches recently opened documents for Home and Quick-Access screens
final recentDocumentsProvider =
    StreamProvider.autoDispose<List<DocumentEntity>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchRecentDocuments();
});

/// Watches favorite documents
final favoriteDocumentsProvider =
    StreamProvider.autoDispose<List<DocumentEntity>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchFavoriteDocuments();
});

/// Provides category counts (e.g. {'all': 45, 'pdf': 20, ...})
final categoryCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  // Re-fetch when documents change
  ref.watch(documentsStreamProvider);
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getCategoryCounts();
});

/// Provides total storage bytes of all indexed documents
final totalStorageBytesProvider =
    FutureProvider.autoDispose<int>((ref) async {
  ref.watch(documentsStreamProvider);
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getTotalStorageBytes();
});

// ── File Operations Controller ──────────────────────────────────────────────

final filesControllerProvider =
    AsyncNotifierProvider<FilesController, void>(FilesController.new);

class FilesController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Trigger full background storage scan
  Future<int> scanDeviceStorage({List<String>? targetRoots}) async {
    ref.read(isScanningProvider.notifier).state = true;
    try {
      final scanner = ref.read(storageScannerServiceProvider);
      final repo = ref.read(documentRepositoryProvider);

      final scannedDocs = await scanner.scanStorage(targetRoots: targetRoots);
      if (scannedDocs.isNotEmpty) {
        await repo.upsertDocuments(scannedDocs);
      }
      ref.invalidate(categoryCountsProvider);
      return scannedDocs.length;
    } on Object catch (e, st) {
      LoggerService.error('Storage scan controller error',
          error: e, stackTrace: st);
      return 0;
    } finally {
      ref.read(isScanningProvider.notifier).state = false;
    }
  }

  /// Pick single or multiple files from device storage
  Future<int> pickAndImportFiles() async {
    final scanner = ref.read(storageScannerServiceProvider);
    final repo = ref.read(documentRepositoryProvider);

    final pickedDocs = await scanner.pickFiles();
    if (pickedDocs.isNotEmpty) {
      await repo.upsertDocuments(pickedDocs);
      ref.invalidate(categoryCountsProvider);
    }
    return pickedDocs.length;
  }

  /// Toggle document favorite
  Future<void> toggleFavorite(DocumentEntity doc) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.toggleFavorite(doc.id, isFavorite: !doc.isFavorite);
  }

  /// Mark document as opened
  Future<void> markOpened(DocumentEntity doc) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.markOpened(doc.id);
  }

  /// Rename document
  Future<DocumentEntity> renameDocument(
      DocumentEntity doc, String newName) async {
    final repo = ref.read(documentRepositoryProvider);
    final updated = await repo.renameDocument(doc.id, newName);
    ref.invalidate(categoryCountsProvider);
    return updated;
  }

  /// Move document to recycle bin
  Future<void> moveToRecycleBin(DocumentEntity doc) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.moveToRecycleBin(doc);
    ref.invalidate(categoryCountsProvider);
  }

  /// Permanently delete document
  Future<void> permanentlyDelete(DocumentEntity doc) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.permanentlyDeleteDocument(doc);
    ref.invalidate(categoryCountsProvider);
  }

  /// Batch delete selected documents
  Future<void> batchDelete(List<DocumentEntity> allDocs) async {
    final selectedIds = ref.read(selectedDocumentIdsProvider);
    final repo = ref.read(documentRepositoryProvider);

    for (final doc in allDocs) {
      if (selectedIds.contains(doc.id)) {
        await repo.moveToRecycleBin(doc);
      }
    }

    ref.read(selectedDocumentIdsProvider.notifier).state = {};
    ref.read(isSelectionModeProvider.notifier).state = false;
    ref.invalidate(categoryCountsProvider);
  }

  /// Batch favorite/unfavorite selected documents
  Future<void> batchSetFavorite(
      List<DocumentEntity> allDocs, {required bool isFavorite}) async {
    final selectedIds = ref.read(selectedDocumentIdsProvider);
    final repo = ref.read(documentRepositoryProvider);

    for (final doc in allDocs) {
      if (selectedIds.contains(doc.id)) {
        await repo.toggleFavorite(doc.id, isFavorite: isFavorite);
      }
    }

    ref.read(selectedDocumentIdsProvider.notifier).state = {};
    ref.read(isSelectionModeProvider.notifier).state = false;
  }
}
