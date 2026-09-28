import 'package:docora/core/services/storage_scanner_service.dart';
import 'package:docora/data/datasources/local/app_database.dart';
import 'package:docora/data/repositories/document_repository_impl.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:docora/domain/repositories/document_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DocumentRepository repo;

  setUp(() {
    // Open clean in-memory database for isolated testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DocumentRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  final doc1 = DocumentEntity(
    id: 1,
    path: '/storage/test/alpha.pdf',
    name: 'alpha.pdf',
    extension: 'pdf',
    mimeType: 'application/pdf',
    sizeBytes: 1048576, // 1 MB
    lastModified: DateTime(2026, 1, 10),
    openCount: 0,
    isFavorite: false,
    isDeleted: false,
    tags: const ['Finance'],
    category: 'pdf',
  );

  final doc2 = DocumentEntity(
    id: 2,
    path: '/storage/test/beta.docx',
    name: 'beta.docx',
    extension: 'docx',
    mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    sizeBytes: 2097152, // 2 MB
    lastModified: DateTime(2026, 2, 20),
    openCount: 2,
    isFavorite: true,
    isDeleted: false,
    tags: const ['Legal'],
    category: 'word',
  );

  final doc3 = DocumentEntity(
    id: 3,
    path: '/storage/test/gamma.xlsx',
    name: 'gamma.xlsx',
    extension: 'xlsx',
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    sizeBytes: 524288, // 0.5 MB
    lastModified: DateTime(2026, 3, 5),
    openCount: 1,
    isFavorite: false,
    isDeleted: false,
    tags: const ['Finance', 'Audit'],
    category: 'excel',
  );

  group('StorageScannerService Tests', () {
    test('contains all expected office, text, and media extensions', () {
      const scanner = StorageScannerService();
      expect(StorageScannerService.supportedExtensions.contains('pdf'), isTrue);
      expect(StorageScannerService.supportedExtensions.contains('docx'), isTrue);
      expect(StorageScannerService.supportedExtensions.contains('xlsx'), isTrue);
      expect(StorageScannerService.supportedExtensions.contains('pptx'), isTrue);
      expect(StorageScannerService.supportedExtensions.contains('txt'), isTrue);
      expect(StorageScannerService.supportedExtensions.contains('epub'), isTrue);
      expect(StorageScannerService.supportedExtensions.contains('zip'), isTrue);
      expect(scanner.getSearchRoots(), isNotEmpty);
    });
  });

  group('DocumentRepository Database Tests', () {
    test('upsertDocument and watchDocuments retrieves all active documents', () async {
      await repo.upsertDocument(doc1);
      await repo.upsertDocument(doc2);

      final docs = await repo.watchDocuments().first;
      expect(docs.length, 2);
    });

    test('batch upsertDocuments saves multiple items', () async {
      await repo.upsertDocuments([doc1, doc2, doc3]);

      final docs = await repo.watchDocuments().first;
      expect(docs.length, 3);
    });

    test('watchDocuments filters by category correctly', () async {
      await repo.upsertDocuments([doc1, doc2, doc3]);

      final pdfDocs = await repo.watchDocuments(category: 'pdf').first;
      expect(pdfDocs.length, 1);
      expect(pdfDocs.first.name, 'alpha.pdf');

      final wordDocs = await repo.watchDocuments(category: 'word').first;
      expect(wordDocs.length, 1);
      expect(wordDocs.first.name, 'beta.docx');
    });

    test('watchDocuments filters by search query on name and tags', () async {
      await repo.upsertDocuments([doc1, doc2, doc3]);

      final queryByName = await repo.watchDocuments(query: 'gamma').first;
      expect(queryByName.length, 1);
      expect(queryByName.first.name, 'gamma.xlsx');

      final queryByTag = await repo.watchDocuments(query: 'Audit').first;
      expect(queryByTag.length, 1);
      expect(queryByTag.first.name, 'gamma.xlsx');
    });

    test('watchDocuments sorts by name, date, and size', () async {
      await repo.upsertDocuments([doc1, doc2, doc3]);

      // By name ascending: alpha, beta, gamma
      final byNameAsc = await repo
          .watchDocuments(sort: DocumentSortOption.nameAsc)
          .first;
      expect(byNameAsc.map((d) => d.name).toList(), ['alpha.pdf', 'beta.docx', 'gamma.xlsx']);

      // By size descending: beta (2MB), alpha (1MB), gamma (0.5MB)
      final bySizeDesc = await repo
          .watchDocuments(sort: DocumentSortOption.sizeDesc)
          .first;
      expect(bySizeDesc.map((d) => d.name).toList(), ['beta.docx', 'alpha.pdf', 'gamma.xlsx']);
    });

    test('toggleFavorite updates favorite state in database', () async {
      await repo.upsertDocument(doc1);
      var fetched = await repo.getDocumentByPath(doc1.path);
      expect(fetched?.isFavorite, isFalse);

      await repo.toggleFavorite(fetched!.id, isFavorite: true);
      fetched = await repo.getDocumentByPath(doc1.path);
      expect(fetched?.isFavorite, isTrue);
    });

    test('markOpened increments open count and updates lastOpened timestamp', () async {
      await repo.upsertDocument(doc1);
      var fetched = await repo.getDocumentByPath(doc1.path);
      expect(fetched?.openCount, 0);
      expect(fetched?.lastOpened, isNull);

      await repo.markOpened(fetched!.id);
      fetched = await repo.getDocumentByPath(doc1.path);
      expect(fetched?.openCount, 1);
      expect(fetched?.lastOpened, isNotNull);
    });

    test('moveToRecycleBin soft-deletes document from active list and records entry', () async {
      await repo.upsertDocuments([doc1, doc2]);

      final fetchedDoc1 = (await repo.getDocumentByPath(doc1.path))!;
      await repo.moveToRecycleBin(fetchedDoc1);

      // Active list should only contain doc2
      final activeDocs = await repo.watchDocuments().first;
      expect(activeDocs.length, 1);
      expect(activeDocs.first.name, 'beta.docx');

      // Recycle bin table should have 1 entry
      final recycleEntries = await db.watchRecycleBin().first;
      expect(recycleEntries.length, 1);
      expect(recycleEntries.first.fileName, 'alpha.pdf');
    });

    test('getCategoryCounts and getTotalStorageBytes calculate correct totals', () async {
      await repo.upsertDocuments([doc1, doc2, doc3]);

      final counts = await repo.getCategoryCounts();
      expect(counts['all'], 3);
      expect(counts['pdf'], 1);
      expect(counts['word'], 1);
      expect(counts['excel'], 1);

      final totalBytes = await repo.getTotalStorageBytes();
      expect(totalBytes, 1048576 + 2097152 + 524288);
    });
  });
}
