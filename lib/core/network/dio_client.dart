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
    } else {
      print('=== AuthInterceptor: sem token para ${options.path} ===');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path   = err.requestOptions.path;
    print('=== AuthInterceptor.onError: status=$status type=${err.type.name} path=$path ===');

    // Trata 401 (não autenticado) e 403 (token expirado/inválido retornado pelo
    // backend como Forbidden). Requisições já marcadas como retry não reentram.
    final isAuthError = status == 401 || status == 403;
    if (!isAuthError || err.requestOptions.extra['_authRetry'] == true) {
      handler.next(err);
      return;
    }

    // ── Refresh já em andamento: apenas aguarda e retenta ──────────────────
    if (_refreshCompleter != null) {
      print('=== AuthInterceptor: aguardando refresh em andamento (${err.requestOptions.path}) ===');
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        await _retryRequest(err, handler, newToken);
      } else {
        handler.next(err);
      }
      return;
    }

    // ── Primeiro 401: executa o refresh ────────────────────────────────────
    print('=== AuthInterceptor: iniciando refresh de token ===');
    _refreshCompleter = Completer<String?>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);

      if (refreshToken == null) {
        print('=== AuthInterceptor: refresh token ausente → expirando sessão ===');
      } else {
        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'_authRetry': true}),
        );
        final newToken = response.data['accessToken'] as String?;

        if (newToken != null) {
          print('=== AuthInterceptor: refresh bem-sucedido, novo token obtido ===');
          await prefs.setString(AppConstants.accessTokenKey, newToken);
          _refreshCompleter!.complete(newToken);
          await _retryRequest(err, handler, newToken);
          return;
        }
        print('=== AuthInterceptor: refresh retornou sem accessToken ===');
      }

      // Refresh token ausente, inválido ou resposta sem accessToken.
      await prefs.clear();
      _refreshCompleter!.complete(null);
      SessionNotifier.instance.expire();
    } catch (e) {
      print('=== AuthInterceptor: refresh falhou com exceção: $e ===');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!(_refreshCompleter?.isCompleted ?? true)) {
        _refreshCompleter!.complete(null);
      }
      SessionNotifier.instance.expire();
    } finally {
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

  /// Retorna true quando a requisição foi cancelada intencionalmente
  /// via CancelToken. Não deve ser exibido como erro na UI.
  bool get isCancelled => message == 'cancelled';

  factory AppException.fromDioError(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return AppException('cancelled');
    }

    // Log completo para diagnóstico — visível em adb logcat no release.
    print('=== AppException [${e.type.name}] '
        'status=${e.response?.statusCode} '
        'url=${e.requestOptions.path} '
        'msg=${e.message} ===');

    // Erros sem resposta do servidor (connection, timeout, SSL, DNS…).
    if (e.response == null) {
      final label = switch (e.type) {
        DioExceptionType.connectionTimeout => 'Tempo de conexão esgotado',
        DioExceptionType.receiveTimeout    => 'Servidor demorou para responder',
        DioExceptionType.sendTimeout       => 'Tempo de envio esgotado',
        DioExceptionType.connectionError   => 'Sem conexão com o servidor',
        DioExceptionType.badCertificate    => 'Erro de certificado SSL',
        _                                  => 'Erro de rede',
      };
      return AppException(label, statusCode: null);
    }

    final status = e.response?.statusCode;
    final data   = e.response?.data;
    final message = data is Map
        ? (data['message'] ?? data['error'] ?? 'Erro no servidor')
        : 'Erro no servidor';
    return AppException(message.toString(), statusCode: status);
  }

  @override
  String toString() => message;
}
