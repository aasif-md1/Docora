import 'package:equatable/equatable.dart';

class RecycleBinEntity extends Equatable {
  const RecycleBinEntity({
    required this.id,
    required this.originalPath,
    required this.fileName,
    required this.category,
    required this.sizeBytes,
    required this.deletedAt,
    required this.purgeAt,
  });

  final int id;
  final String originalPath;
  final String fileName;
  final String category;
  final int sizeBytes;
  final DateTime deletedAt;
  final DateTime purgeAt;

  /// Days remaining before auto-purge
  int get daysUntilPurge =>
      purgeAt.difference(DateTime.now()).inDays.clamp(0, 30);

  @override
  List<Object?> get props =>
      [id, originalPath, fileName, category, sizeBytes, deletedAt, purgeAt];
}
