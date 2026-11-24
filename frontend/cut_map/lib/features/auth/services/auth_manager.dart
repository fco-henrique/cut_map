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
  Future<void>? _initFuture;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  UserModel? get user => _user;

  AuthManager({
    required this.storage,
    required this.authService,
    bool autoInitialize = true,
  }) {
    if (autoInitialize) {
      initialize();
    }
  }

  Future<void> initialize() {
    return _initFuture ??= _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final accessToken = await storage.readAccessToken();
    final refreshToken = await storage.readRefreshToken();

    final hasAccess = accessToken != null && accessToken.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;

    if (!hasAccess && !hasRefresh) {
      _isLoggedIn = false;
      _user = null;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      if (!hasAccess && hasRefresh) {
        await authService.refreshSession(refreshToken);
      }

      _user = await authService.getCurrentUser();
      _isLoggedIn = true;
    } on AuthSessionInvalidException {
      await storage.deleteTokens();
      _isLoggedIn = false;
      _user = null;
    } catch (_) {
      // Sem confirmação da API/refresh, a sessão não é considerada válida.
      _isLoggedIn = false;
      _user = null;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storage.saveTokens(accessToken, refreshToken);

    try {
      _user = await authService.getCurrentUser();
    } on AuthSessionInvalidException {
      await storage.deleteTokens();
      _user = null;
      _isLoggedIn = false;
      notifyListeners();
      rethrow;
    } catch (_) {
      _user = null;
    }

    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final refreshToken = await storage.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await authService.logout(refreshToken);
      }
    } catch (_) {
      // Uma falha de rede não deve impedir o encerramento local da sessão.
    } finally {
      await storage.deleteTokens();
      _isLoggedIn = false;
      _user = null;
      notifyListeners();
    }
  }
}
