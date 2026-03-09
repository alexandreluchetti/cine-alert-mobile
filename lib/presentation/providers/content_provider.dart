import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/content_entity.dart';
import '../../data/repositories/content_repository.dart';

// Trending
final trendingProvider = FutureProvider<List<ContentEntity>>((ref) async {
  return ref.watch(contentRepositoryProvider).getTrending();
});

// Genres
final genresProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(contentRepositoryProvider).getGenres();
});

// Search
class SearchState {
  final List<ContentEntity> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<ContentEntity>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) =>
      SearchState(
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        query: query ?? this.query,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ContentRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query, {
    String? type, String? genre, int? year, double? minRating,
  }) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(isLoading: true, query: query, error: null);
    try {
      final results = await _repository.search(
        query, type: type, genre: genre, year: year, minRating: minRating,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), results: []);
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(contentRepositoryProvider));
});

// Content detail
final contentDetailProvider = FutureProvider.family<ContentEntity, String>((ref, imdbId) async {
  return ref.watch(contentRepositoryProvider).getDetail(imdbId);
});
