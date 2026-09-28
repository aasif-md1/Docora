import 'dart:typed_data';

/// A single chapter or section in an EPUB publication.
class EpubChapter {
  const EpubChapter({
    required this.id,
    required this.title,
    required this.href,
    required this.htmlContent,
    required this.chapterIndex,
  });

  final String id;
  final String title;
  final String href;
  final String htmlContent;
  final int chapterIndex;

  /// Plain text representation stripped of HTML tags for search and stats.
  String get plainText =>
      htmlContent.replaceAll(RegExp('<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// A Table of Contents navigation entry for an EPUB document.
class EpubTocEntry {
  const EpubTocEntry({
    required this.title,
    required this.href,
    this.targetChapterIndex = 0,
    this.children = const [],
  });

  final String title;
  final String href;
  final int targetChapterIndex;
  final List<EpubTocEntry> children;
}

/// Complete in-memory representation of a loaded EPUB e-book.
class EpubDocument {
  const EpubDocument({
    required this.title,
    required this.filePath,
    required this.fileSizeBytes,
    required this.chapters,
    required this.toc,
    this.author,
    this.description,
    this.publisher,
    this.coverImageBytes,
  });

  factory EpubDocument.empty({
    String title = '',
    String filePath = '',
  }) =>
      EpubDocument(
        title: title,
        filePath: filePath,
        fileSizeBytes: 0,
        chapters: const [],
        toc: const [],
      );

  final String title;
  final String filePath;
  final int fileSizeBytes;
  final List<EpubChapter> chapters;
  final List<EpubTocEntry> toc;
  final String? author;
  final String? description;
  final String? publisher;
  final Uint8List? coverImageBytes;

  int get chapterCount => chapters.length;

  bool get hasCover => coverImageBytes != null && coverImageBytes!.isNotEmpty;

  EpubChapter? getChapter(int index) {
    if (index >= 0 && index < chapters.length) {
      return chapters[index];
    }
    return null;
  }
}
