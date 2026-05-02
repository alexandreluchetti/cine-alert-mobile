import 'package:flutter/foundation.dart';

/// Bridge entre o AuthInterceptor (Dio) e o GoRouter.
/// Sinaliza expiração de sessão (token inválido / refresh falhou).
class SessionNotifier extends ChangeNotifier {
  SessionNotifier._();
  static final instance = SessionNotifier._();

  bool _isSessionExpired = false;
  bool get isSessionExpired => _isSessionExpired;

  void expire() {
    if (!_isSessionExpired) {
      _isSessionExpired = true;
      notifyListeners();
    }
  }

  void reset() {
    if (_isSessionExpired) {
      _isSessionExpired = false;
      notifyListeners();
    }
  }
}

/// Bridge entre o AuthNotifier (Riverpod) e o GoRouter.
/// Sinaliza mudanças de autenticação (login / logout) sem depender
/// do BuildContext da tela — evita o problema de context obsoleto
/// após gaps de async em ConsumerWidget.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier._();
  static final instance = AuthStateNotifier._();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      notifyListeners();
    }
  }
}
