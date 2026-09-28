import 'package:equatable/equatable.dart';

class BookmarkEntity extends Equatable {
  const BookmarkEntity({
    required this.id,
    required this.documentId,
    required this.documentPath,
    required this.label,
    required this.createdAt,
    this.pageIndex,
    this.scrollPosition,
  });

  final int id;
  final int documentId;
  final String documentPath;
  final int? pageIndex;
  final double? scrollPosition;
  final String label;
  final DateTime createdAt;

  BookmarkEntity copyWith({
    int? id,
    int? documentId,
    String? documentPath,
    int? pageIndex,
    double? scrollPosition,
    String? label,
    DateTime? createdAt,
  }) => BookmarkEntity(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        documentPath: documentPath ?? this.documentPath,
        pageIndex: pageIndex ?? this.pageIndex,
        scrollPosition: scrollPosition ?? this.scrollPosition,
        label: label ?? this.label,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, documentId, documentPath, pageIndex, scrollPosition, label, createdAt];
}
