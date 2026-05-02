import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'session_notifier.dart';

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
  dio.interceptors.add(LogInterceptor(
    requestBody: true, 
    responseBody: true,
  ));

  return dio;
});

class AuthInterceptor extends Interceptor {
  final Dio dio;

  // Completer compartilhado entre todas as requisições 401 concorrentes.
  // null  → nenhum refresh em andamento.
  // !null → refresh em andamento; demais requisições aguardam o mesmo Future.
  Completer<String?>? _refreshCompleter;

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
    // Só trata 401. Requisições já marcadas como retry não entram no loop.
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['_authRetry'] == true) {
      handler.next(err);
      return;
    }

    // ── Refresh já em andamento: apenas aguarda e retenta ──────────────────
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        await _retryRequest(err, handler, newToken);
      } else {
        handler.next(err);
      }
      return;
    }

    // ── Primeiro 401: executa o refresh ────────────────────────────────────
    _refreshCompleter = Completer<String?>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

      if (refreshToken != null) {
        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          // Marca a requisição de refresh para não reentrar neste interceptor.
          options: Options(extra: {'_authRetry': true}),
        );
        final newToken = response.data['accessToken'] as String?;

        if (newToken != null) {
          await prefs.setString(AppConstants.accessTokenKey, newToken);

          // Desbloqueia todas as requisições que estavam aguardando.
          _refreshCompleter!.complete(newToken);

          // Retenta a requisição que iniciou o refresh.
          await _retryRequest(err, handler, newToken);
          return;
        }
      }

      // Refresh token ausente, inválido ou resposta sem accessToken.
      await prefs.clear();
      _refreshCompleter!.complete(null);
      SessionNotifier.instance.expire();
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!(_refreshCompleter?.isCompleted ?? true)) {
        _refreshCompleter!.complete(null);
      }
      SessionNotifier.instance.expire();
    } finally {
      // Limpa o completer para o próximo ciclo de refresh.
      _refreshCompleter = null;
    }

    handler.next(err);
  }

  /// Retenta a requisição original com o novo token.
  Future<void> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
    String newToken,
  ) async {
    err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
    err.requestOptions.extra['_authRetry'] = true;
    try {
      final retried = await dio.fetch(err.requestOptions);
      handler.resolve(retried);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    } catch (_) {
      handler.next(err);
    }
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
