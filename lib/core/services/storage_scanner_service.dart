import 'dart:io';

import 'package:docora/core/services/logger_service.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/domain/entities/document_entity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Parameters for background isolate directory scan
class _ScanParams {
  const _ScanParams({
    required this.rootPaths,
    required this.supportedExtensions,
    required this.ignoredFolderNames,
  });

  final List<String> rootPaths;
  final Set<String> supportedExtensions;
  final Set<String> ignoredFolderNames;
}

/// Discovers, parses, and indexes document files across device storage.
/// Performs disk traversal inside a background Isolate for zero UI lag.
class StorageScannerService {
  const StorageScannerService();

  static const Set<String> supportedExtensions = {
    'pdf',
    'doc',
    'docx',
    'rtf',
    'odt',
    'xls',
    'xlsx',
    'csv',
    'tsv',
    'ods',
    'ppt',
    'pptx',
    'odp',
    'txt',
    'md',
    'markdown',
    'log',
    'json',
    'xml',
    'yaml',
    'yml',
    'dart',
    'py',
    'js',
    'ts',
    'html',
    'css',
    'epub',
    'mobi',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'svg',
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
  };

  static const Set<String> ignoredFolderNames = {
    'android',
    'cache',
    '.thumbnails',
    '.trash',
    'lost.dir',
  };

  /// Discovers standard directories on Android or fallback for other platforms
  List<String> getSearchRoots() {
    if (Platform.isAndroid) {
      final roots = <String>[];
      const standardDirs = [
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Download/Telegram',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
        '/sdcard/Download',
        '/sdcard/Documents',
      ];

      for (final dir in standardDirs) {
        try {
          if (Directory(dir).existsSync()) {
            roots.add(dir);
          }
        } catch (_) {}
      }

      final primary = Directory('/storage/emulated/0');
      try {
        if (primary.existsSync()) {
          roots.add('/storage/emulated/0');
        }
      } catch (_) {}

      // Check for external SD card partitions in /storage
      try {
        final storageDir = Directory('/storage');
        if (storageDir.existsSync()) {
          for (final entity in storageDir.listSync()) {
            if (entity is Directory) {
              final name = p.basename(entity.path);
              if (name != 'emulated' && name != 'self' && !name.startsWith('.')) {
                roots.add(entity.path);
                final extDoc = '${entity.path}/Documents';
                final extDl = '${entity.path}/Download';
                if (Directory(extDoc).existsSync()) roots.add(extDoc);
                if (Directory(extDl).existsSync()) roots.add(extDl);
              }
            }
          }
        }
      } catch (_) {}

      return roots.isEmpty ? ['/sdcard', '/storage/emulated/0'] : roots.toSet().toList();
    } else {
      // Desktop / Test environment fallback
      return [Directory.current.path];
    }
  }

  /// Scans device storage in a background isolate and returns discovered documents
  Future<List<DocumentEntity>> scanStorage({List<String>? targetRoots}) async {
    final roots = targetRoots ?? getSearchRoots();
    LoggerService.info('Starting storage scan across roots: $roots');

    try {
      final params = _ScanParams(
        rootPaths: roots,
        supportedExtensions: supportedExtensions,
        ignoredFolderNames: ignoredFolderNames,
      );

      final results = await compute(_scanIsolateWorker, params);
      LoggerService.info('Storage scan complete: found ${results.length} documents.');
      return results;
    } on Object catch (e, st) {
      LoggerService.error('Storage scan failed', error: e, stackTrace: st);
      return [];
    }
  }

  /// Lets the user pick one or more files using the system file picker
  Future<List<DocumentEntity>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final entities = <DocumentEntity>[];
      for (final picked in result.files) {
        if (picked.path == null) continue;
        final file = File(picked.path!);
        if (!file.existsSync()) continue;

        final stat = file.statSync();
        final ext = p.extension(file.path).replaceAll('.', '').toLowerCase();
        final format = DocumentFormat.fromExtension(ext);
        final mime = lookupMimeType(file.path) ?? 'application/octet-stream';

        entities.add(
          DocumentEntity(
            id: 0,
            path: file.path,
            name: p.basename(file.path),
            extension: ext,
            mimeType: mime,
            sizeBytes: stat.size,
            lastModified: stat.modified,
            openCount: 0,
            isFavorite: false,
            isDeleted: false,
            tags: const [],
            category: format.name,
          ),
        );
      }

      return entities;
    } on Object catch (e, st) {
      LoggerService.error('File pick failed', error: e, stackTrace: st);
      return [];
    }
  }

  /// Lets the user select an entire directory and scans it
  Future<List<DocumentEntity>> pickAndScanFolder() async {
    try {
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return [];

      return scanStorage(targetRoots: [directoryPath]);
    } on Object catch (e, st) {
      LoggerService.error('Folder pick failed', error: e, stackTrace: st);
      return [];
    }
  }
}

/// Top-level worker function executing inside background Isolate via [compute]
List<DocumentEntity> _scanIsolateWorker(_ScanParams params) {
  final foundDocs = <DocumentEntity>[];
  final visitedPaths = <String>{};

  for (final rootPath in params.rootPaths) {
    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) continue;

    try {
      _scanDirectoryRecursive(
        rootDir,
        params.supportedExtensions,
        params.ignoredFolderNames,
        visitedPaths,
        foundDocs,
        depth: 0,
        maxDepth: 6,
      );
    } on Object catch (_) {
      // Ignore root traversal permission errors
    }
  }

  return foundDocs;
}

void _scanDirectoryRecursive(
  Directory dir,
  Set<String> extensions,
  Set<String> ignoredFolders,
  Set<String> visitedPaths,
  List<DocumentEntity> outResults, {
  required int depth,
  required int maxDepth,
}) {
  if (depth > maxDepth) return;

  final dirName = p.basename(dir.path).toLowerCase();
  if (dirName.startsWith('.') || ignoredFolders.contains(dirName)) {
    return;
  }

  List<FileSystemEntity> entities;
  try {
    entities = dir.listSync(followLinks: false);
  } on Object catch (_) {
    // Permission denied or unreadable directory — skip gracefully
    return;
  }

  for (final entity in entities) {
    final entityPath = entity.path;
    final name = p.basename(entityPath);

    if (name.startsWith('.')) continue;

    if (entity is Directory) {
      final lowerName = name.toLowerCase();
      if (!ignoredFolders.contains(lowerName)) {
        _scanDirectoryRecursive(
          entity,
          extensions,
          ignoredFolders,
          visitedPaths,
          outResults,
          depth: depth + 1,
          maxDepth: maxDepth,
        );
      }
    } else if (entity is File) {
      if (visitedPaths.contains(entityPath)) continue;

      final ext = p.extension(entityPath).replaceAll('.', '').toLowerCase();
      if (extensions.contains(ext)) {
        try {
          final stat = entity.statSync();
          if (stat.size <= 0) continue; // Ignore empty 0-byte files

          final mime = lookupMimeType(entityPath) ?? 'application/octet-stream';
          final format = DocumentFormat.fromExtension(ext);

          visitedPaths.add(entityPath);
          outResults.add(
            DocumentEntity(
              id: 0,
              path: entityPath,
              name: name,
              extension: ext,
              mimeType: mime,
              sizeBytes: stat.size,
              lastModified: stat.modified,
              openCount: 0,
              isFavorite: false,
              isDeleted: false,
              tags: const [],
              category: format.name,
            ),
          );
        } on Object catch (_) {
          // File was deleted or unreadable while scanning
        }
      }
    }
  }
}
