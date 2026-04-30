import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_entity.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/notifications/notification_service.dart';

// Auth state
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final AuthEntity auth;
  AuthAuthenticated(this.auth);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthInitial()) {
    NotificationService.instance.onTokenRefresh = (token) {
      _repository.updateFcmToken(token);
    };
  }

  Future<bool> checkAuthentication() async {
    final isAuth = await _repository.isAuthenticated();
    if (!isAuth) {
      state = AuthUnauthenticated();
    } else {
      // Se autenticado no início, tenta sincronizar o token FCM
      _syncFcmToken();
    }
    return isAuth;
  }

  Future<bool> login(String email, String password) async {
    state = AuthLoading();
    try {
      final auth = await _repository.login(email, password);
      state = AuthAuthenticated(auth);
      _syncFcmToken();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = AuthLoading();
    try {
      final auth = await _repository.register(name, email, password);
      state = AuthAuthenticated(auth);
      _syncFcmToken();
      return true;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  Future<void> _syncFcmToken() async {
    final token = await NotificationService.instance.getFcmToken();
    if (token != null) {
      await _repository.updateFcmToken(token);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = AuthUnauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
