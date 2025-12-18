import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Model for Pagination
class ClientPaginationFilters {
  final int page;
  final int limit;

  ClientPaginationFilters({this.page = 1, this.limit = 10}); // Default limit 15

  ClientPaginationFilters copyWith({int? page, int? limit}) {
    return ClientPaginationFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// 2. State Provider for Filters
final materialClientPaginationProvider = StateProvider<ClientPaginationFilters>(
  (ref) => ClientPaginationFilters(),
);
