import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/content_entity.dart';
import '../../data/repositories/content_repository.dart';

// ─── Trending ────────────────────────────────────────────────────────────────

final trendingProvider = FutureProvider<List<ContentEntity>>((ref) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.watch(contentRepositoryProvider).getTrending(cancelToken: cancelToken);
});

// ─── Genres ──────────────────────────────────────────────────────────────────

final genresProvider = FutureProvider<List<String>>((ref) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.watch(contentRepositoryProvider).getGenres();
});

// ─── Content detail ───────────────────────────────────────────────────────────
// autoDispose garante que o provider é descartado quando TitleDetailScreen
// sai da árvore, cancelando a requisição em andamento via onDispose.

final contentDetailProvider =
    FutureProvider.autoDispose.family<ContentEntity, String>((ref, imdbId) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .watch(contentRepositoryProvider)
      .getDetail(imdbId, cancelToken: cancelToken);
});

// ─── Search ───────────────────────────────────────────────────────────────────

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

  // Token reutilizável: substituído a cada nova busca para cancelar a anterior.
  CancelToken _cancelToken = CancelToken();

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(
    String query, {
    String? type,
    String? genre,
    int? year,
    double? minRating,
  }) async {
    // Cancela busca anterior antes de iniciar a nova.
    _cancelToken.cancel();
    _cancelToken = CancelToken();

    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query, error: null);
    try {
      final results = await _repository.search(
        query,
        type: type,
        genre: genre,
        year: year,
        minRating: minRating,
        cancelToken: _cancelToken,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      // Cancelamento intencional — sai silenciosamente sem alterar a UI.
      if (e is AppException && e.isCancelled) return;
      state = state.copyWith(isLoading: false, error: e.toString(), results: []);
    }
  }

  void clear() => state = const SearchState();

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(contentRepositoryProvider));
});
