import 'package:equatable/equatable.dart';

/// Core domain entity representing a document in Docora.
/// This is a pure Dart class — no Flutter, no Isar, no JSON dependencies.
class DocumentEntity extends Equatable {
  const DocumentEntity({
    required this.id,
    required this.path,
    required this.name,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.lastModified,
    required this.openCount,
    required this.isFavorite,
    required this.isDeleted,
    required this.tags,
    required this.category,
    this.lastOpened,
    this.pageCount,
    this.thumbnailPath,
    this.author,
    this.title,
  });

  final int id;

  /// Absolute file path or content:// URI
  final String path;

  final String name;
  final String extension;
  final String mimeType;
  final int sizeBytes;
  final DateTime lastModified;
  final DateTime? lastOpened;
  final int openCount;
  final bool isFavorite;
  final bool isDeleted;
  final List<String> tags;
  final int? pageCount;
  final String? thumbnailPath;

  /// Logical category: 'pdf' | 'word' | 'excel' | 'ppt' | 'text' | 'epub' | 'image' | 'archive'
  final String category;

  final String? author;
  final String? title;

  /// Human-readable file size (e.g., "2.4 MB")
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Reading progress percentage (0.0 to 1.0), or null if unknown
  double? readingProgress(int? lastPage) {
    if (lastPage == null || pageCount == null || pageCount == 0) return null;
    return (lastPage + 1) / pageCount!;
  }

  DocumentEntity copyWith({
    int? id,
    String? path,
    String? name,
    String? extension,
    String? mimeType,
    int? sizeBytes,
    DateTime? lastModified,
    DateTime? lastOpened,
    int? openCount,
    bool? isFavorite,
    bool? isDeleted,
    List<String>? tags,
    int? pageCount,
    String? thumbnailPath,
    String? category,
    String? author,
    String? title,
  }) => DocumentEntity(
        id: id ?? this.id,
        path: path ?? this.path,
        name: name ?? this.name,
        extension: extension ?? this.extension,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        lastModified: lastModified ?? this.lastModified,
        lastOpened: lastOpened ?? this.lastOpened,
        openCount: openCount ?? this.openCount,
        isFavorite: isFavorite ?? this.isFavorite,
        isDeleted: isDeleted ?? this.isDeleted,
        tags: tags ?? this.tags,
        pageCount: pageCount ?? this.pageCount,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        category: category ?? this.category,
        author: author ?? this.author,
        title: title ?? this.title,
      );

  @override
  List<Object?> get props => [
        id, path, name, extension, mimeType, sizeBytes,
        lastModified, lastOpened, openCount, isFavorite,
        isDeleted, tags, pageCount, thumbnailPath, category, author, title,
      ];
}
