import 'package:equatable/equatable.dart';

class SearchHistoryEntity extends Equatable {
  const SearchHistoryEntity({
    required this.id,
    required this.query,
    required this.searchedAt,
  });

  final int id;
  final String query;
  final DateTime searchedAt;

  @override
  List<Object?> get props => [id, query, searchedAt];
}
