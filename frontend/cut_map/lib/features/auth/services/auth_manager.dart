import 'package:cut_map/core/storage/token_storage.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/models/user_model.dart';
import 'package:flutter/material.dart';

class AuthManager extends ChangeNotifier {
  final TokenStorage storage;
  final AuthService authService;

  bool _isLoggedIn = false;
  bool _isInitialized = false;
  UserModel? _user;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  UserModel? get user => _user;

  AuthManager({required this.storage, required this.authService}) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final accessToken = await storage.readAccessToken();
    final refreshToken = await storage.readRefreshToken();

    _isLoggedIn =
        (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);

    if (_isLoggedIn) {
      await _fetchCurrentUser();
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      _user = await authService.getCurrentUser();
    } catch (_) {
      // Se o token estiver expirado/inválido, não derruba o app aqui;
      // deixa o interceptor de refresh/401 (se houver) ou uma próxima
      // chamada autenticada lidar com isso. O nome só fica vazio até lá.
      _user = null;
    }
  }

  Future<void> login({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storage.saveTokens(accessToken, refreshToken);

    _isLoggedIn = true;
    await _fetchCurrentUser();
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.deleteTokens();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
}