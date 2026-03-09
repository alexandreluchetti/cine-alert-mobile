import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl + AppConstants.apiPrefix,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(dio));

  return dio;
});

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

        if (refreshToken != null) {
          final response = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
          final newToken = response.data['accessToken'] as String?;

          if (newToken != null) {
            await prefs.setString(AppConstants.accessTokenKey, newToken);
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retried = await dio.fetch(err.requestOptions);
            handler.resolve(retried);
            return;
          }
        }
      } catch (_) {
        // Clear tokens on failure
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  factory AppException.fromDioError(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? (data['message'] ?? 'An error occurred') : 'An error occurred';
    return AppException(message.toString(), statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
