import 'package:cut_map/core/storage/token_storage.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:dio/dio.dart';

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.103:3000',
  );

  static const _publicAuthPaths = {
    '/user',
    '/auth/login',
    '/auth/refresh',
    '/auth/logout',
    '/auth/verify-email',
    '/auth/resend-verification',
    '/auth/forgot-password',
    '/auth/verify-reset-code',
    '/auth/reset-password',
  };

  final Dio dio;
  final TokenStorage storage;
  final Dio _refreshDio;
  final Future<void> Function()? _onSessionExpired;
  Future<String>? _pendingRefresh;

  Future<String> _refreshAccessToken(String refreshToken) async {
    final response = await _refreshDio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final accessToken = response.data['accessToken'];
    final nextRefreshToken = response.data['refreshToken'];
    if (accessToken is! String || nextRefreshToken is! String) {
      throw StateError('Resposta de renovação inválida.');
    }
    await storage.saveTokens(accessToken, nextRefreshToken);
    return accessToken;
  }

  /// Renova o par de tokens usando o [refreshToken] atual, compartilhando
  /// eventual requisição de refresh em andamento.
  Future<String> refreshSession(String refreshToken) async {
    try {
      final pending = _pendingRefresh ??= _refreshAccessToken(refreshToken);
      return await pending;
    } finally {
      _pendingRefresh = null;
    }
  }

  Future<void> _notifySessionExpired() async {
    if (_onSessionExpired != null) {
      await _onSessionExpired();
      return;
    }
    if (locator.isRegistered<AuthManager>()) {
      await locator<AuthManager>().logout();
    }
  }

  ApiClient({
    required this.storage,
    Dio? dio,
    Dio? refreshDio,
    Future<void> Function()? onSessionExpired,
  }) : dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl)),
       _onSessionExpired = onSessionExpired {
    this.dio.options = BaseOptions(baseUrl: baseUrl);

    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_publicAuthPaths.contains(options.path) &&
              !options.headers.containsKey('Authorization')) {
            final token = await storage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode != 401 ||
              _publicAuthPaths.contains(e.requestOptions.path) ||
              e.requestOptions.extra['retriedAfterRefresh'] == true) {
            return handler.next(e);
          }

          final requestToken = e.requestOptions.headers['Authorization'];
          final accessToken = await storage.readAccessToken();
          final refreshToken = await storage.readRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            return handler.next(e);
          }

          // Outra chamada pode já ter renovado o token desta requisição.
          if (accessToken != null &&
              accessToken.isNotEmpty &&
              requestToken is String &&
              requestToken != 'Bearer $accessToken' &&
              _pendingRefresh == null) {
            e.requestOptions.extra['retriedAfterRefresh'] = true;
            e.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
            try {
              return handler.resolve(await this.dio.fetch(e.requestOptions));
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }

          String newAccessToken;
          try {
            newAccessToken = await refreshSession(refreshToken);
          } catch (_) {
            await _notifySessionExpired();
            return handler.next(e);
          }

          e.requestOptions.extra['retriedAfterRefresh'] = true;
          e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            return handler.resolve(await this.dio.fetch(e.requestOptions));
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }
}
