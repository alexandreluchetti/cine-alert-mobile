import 'package:flutter/foundation.dart';

/// Bridge entre o AuthInterceptor (Dio) e o GoRouter.
/// Evita dependência circular entre dioProvider e authProvider.
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
