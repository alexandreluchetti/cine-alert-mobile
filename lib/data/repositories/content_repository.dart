import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/content_entity.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(dioProvider));
});

class ContentRepository {
  final Dio _dio;

  ContentRepository(this._dio);

  Future<List<ContentEntity>> search(
    String query, {
    String? type,
    String? genre,
    int? year,
    double? minRating,
  }) async {
    try {
      final params = <String, dynamic>{'q': query};
      if (type != null) params['type'] = type;
      if (genre != null) params['genre'] = genre;
      if (year != null) params['year'] = year;
      if (minRating != null) params['rating'] = minRating;

      final response =
          await _dio.get('/content/search', queryParameters: params);
      return (response.data as List).map((e) => _parseContent(e)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<ContentEntity> getDetail(String imdbId) async {
    try {
      final response = await _dio.get('/content/$imdbId');
      return _parseContent(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<List<ContentEntity>> getTrending() async {
    try {
      final response = await _dio.get('/content/trending/movies');
      return (response.data as List).map((e) => _parseContent(e)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<List<String>> getGenres() async {
    try {
      final response = await _dio.get('/content/genres');
      return (response.data as List).map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  ContentEntity _parseContent(Map<String, dynamic> data) {
    return ContentEntity(
      id: data['id'],
      imdbId: data['imdbId'] ?? '',
      title: data['title'] ?? 'Unknown',
      type: data['type'] ?? 'MOVIE',
      posterUrl: data['posterUrl'],
      year: data['year'],
      rating: data['rating'] != null
          ? double.tryParse(data['rating'].toString())
          : null,
      genre: data['genre'],
      synopsis: data['synopsis'],
      trailerUrl: data['trailerUrl'],
      runtimeMinutes: data['runtimeMinutes'],
    );
  }
}
