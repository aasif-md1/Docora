import 'package:equatable/equatable.dart';

class CollectionEntity extends Equatable {
  const CollectionEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.documentPaths,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String colorHex;
  final List<String> documentPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get documentCount => documentPaths.length;

  CollectionEntity copyWith({
    int? id,
    String? name,
    String? colorHex,
    List<String>? documentPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CollectionEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        documentPaths: documentPaths ?? this.documentPaths,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, name, colorHex, documentPaths, createdAt, updatedAt];
}
