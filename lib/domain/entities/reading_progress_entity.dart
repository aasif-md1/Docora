import 'package:equatable/equatable.dart';

class ReadingProgressEntity extends Equatable {
  const ReadingProgressEntity({
    required this.id,
    required this.documentPath,
    required this.updatedAt,
    this.lastPageIndex,
    this.scrollOffset,
    this.totalPages,
  });

  final int id;
  final String documentPath;
  final int? lastPageIndex;
  final double? scrollOffset;
  final int? totalPages;
  final DateTime updatedAt;

  /// Progress as a value 0.0–1.0, or null if indeterminate
  double? get progressFraction {
    if (lastPageIndex == null || totalPages == null || totalPages == 0) {
      return null;
    }
    return (lastPageIndex! + 1) / totalPages!;
  }

  @override
  List<Object?> get props =>
      [id, documentPath, lastPageIndex, scrollOffset, totalPages, updatedAt];
}
