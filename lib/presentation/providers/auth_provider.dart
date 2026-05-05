import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_entity.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/network/session_notifier.dart';

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
    final storedAuth = await _repository.getStoredAuth();
    if (storedAuth == null) {
      state = AuthUnauthenticated();
      AuthStateNotifier.instance.setAuthenticated(false);
      return false;
    }
    state = AuthAuthenticated(storedAuth);
    AuthStateNotifier.instance.setAuthenticated(true);
    // Fire-and-forget: o AuthInterceptor garante o refresh do access token
    // automaticamente no primeiro 401. Awaitar aqui bloquearia o cold start
    // na splash (getToken() faz requisição de rede) e poderia deixar o
    // _refreshCompleter em estado intermediário ao iniciar os providers.
    _syncFcmToken();
    return true;
  }

  Future<bool> login(String email, String password) async {
    state = AuthLoading();
    try {
      final auth = await _repository.login(email, password);
      state = AuthAuthenticated(auth);
      SessionNotifier.instance.reset();
      AuthStateNotifier.instance.setAuthenticated(true);
      await _syncFcmToken();
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
      SessionNotifier.instance.reset();
      AuthStateNotifier.instance.setAuthenticated(true);
      await _syncFcmToken();
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
      print('=== FCM token synced ===');
    } else {
      print('=== FCM token sync skipped: token null ===');
    }
  }

  Future<bool> updateName(String name) async {
    final current = state;
    if (current is! AuthAuthenticated) return false;
    try {
      await _repository.updateProfile(name: name);
      // Atualiza o state com o novo nome sem recriar tokens.
      state = AuthAuthenticated(
        AuthEntity(
          accessToken: current.auth.accessToken,
          refreshToken: current.auth.refreshToken,
          tokenType: current.auth.tokenType,
          expiresIn: current.auth.expiresIn,
          user: UserInfo(
            id: current.auth.user.id,
            name: name,
            email: current.auth.user.email,
            avatarUrl: current.auth.user.avatarUrl,
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthUnauthenticated();
    // Dispara o redirect do GoRouter sem depender do BuildContext da tela.
    AuthStateNotifier.instance.setAuthenticated(false);
  }

  void clearError() {
    if (state is AuthError) state = AuthUnauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Contador incrementado pelo MainShell sempre que o app volta ao foreground
/// após um período prolongado em background (≥5 min). As telas escutam este
/// provider via [ref.listen] para recarregar seus dados sem precisar de
/// lifecycle observers individuais.
final sessionRefreshProvider = StateProvider<int>((_) => 0);
