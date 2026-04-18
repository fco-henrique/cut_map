import 'package:cut_map/services/token_storage.dart';
import 'package:flutter/material.dart';

class AuthManager extends ChangeNotifier {
  final TokenStorage storage;

  bool _isLoggedIn = false;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  AuthManager({required this.storage}) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final accessToken = await storage.readAccessToken();
    final refreshToken = await storage.readRefreshToken();

    _isLoggedIn =
        (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);

    _isInitialized = true;
    notifyListeners(); 
  }

  Future<void> login({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storage.saveTokens(accessToken, refreshToken);

    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.deleteTokens();
    _isLoggedIn = false;
    notifyListeners();
  }
}
