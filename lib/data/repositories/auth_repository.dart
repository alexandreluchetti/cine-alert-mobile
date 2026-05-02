import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/auth_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthEntity> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final entity = _parseAuth(response.data);
      await _saveTokens(entity);
      return entity;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<AuthEntity> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final entity = _parseAuth(response.data);
      await _saveTokens(entity);
      return entity;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.put('/users/me/fcm-token', data: {'token': token});
    } on DioException catch (e) {
      // Falha silenciosa ou logar, fcm token não deve travar o app
      print('=== Failed to update FCM token: $e ===');
    }
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null;
  }

  /// Reconstrói o [AuthEntity] a partir do que foi persistido localmente.
  /// Retorna null se os dados estiverem incompletos ou ausentes.
  Future<AuthEntity?> getStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(AppConstants.accessTokenKey);
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    final userJson = prefs.getString(AppConstants.userKey);

    if (accessToken == null || refreshToken == null || userJson == null) {
      return null;
    }

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: 'Bearer',
        expiresIn: 0,
        user: UserInfo(
          id: userMap['id'] as String,
          name: userMap['name'] as String,
          email: userMap['email'] as String,
          avatarUrl: userMap['avatarUrl'] as String?,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTokens(AuthEntity entity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, entity.accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, entity.refreshToken);
    await prefs.setString(
      AppConstants.userKey,
      jsonEncode({
        'id': entity.user.id,
        'name': entity.user.name,
        'email': entity.user.email,
        'avatarUrl': entity.user.avatarUrl,
      }),
    );
  }

  AuthEntity _parseAuth(Map<String, dynamic> data) {
    final userMap = data['user'] as Map<String, dynamic>;
    return AuthEntity(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
      tokenType: data['tokenType'] ?? 'Bearer',
      expiresIn: data['expiresIn'] ?? 3600,
      user: UserInfo(
        id: userMap['id'],
        name: userMap['name'],
        email: userMap['email'],
        avatarUrl: userMap['avatarUrl'],
      ),
    );
  }
}
