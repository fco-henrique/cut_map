import 'package:cut_map/core/network/api_client.dart';
import 'package:cut_map/core/network/api_error_handler.dart';
import 'package:cut_map/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum AuthStateType { uninitialized, authenticated, unauthenticated }

class AuthState {
  final AuthStateType type;
  final String? role;

  const AuthState({required this.type, this.role});
}

class AuthService with ChangeNotifier {
  final ApiClient api;

  AuthService({required this.api});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await api.dio.post(
        '/user',
        data: {'name': name, 'email': email, 'password': password},
      );
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  Future<Map<String, String>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await api.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];

        if (accessToken == null || refreshToken == null) {
          throw 'Resposta do servidor não contém tokens válidos.';
        }

        return {'accessToken': accessToken, 'refreshToken': refreshToken};
      }

      throw 'Falha ao autenticar: código HTTP ${response.statusCode}.';
    } catch (e) {
      throw ApiErrorHandler.handleError(
        e,
        fallbackMessage: 'Credenciais inválidas ou erro de conexão.',
      );
    }
  }

  Future<Map<String, String>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await api.dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final accessToken = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];

        if (accessToken == null || refreshToken == null) {
          throw 'Resposta do servidor não contém tokens válidos.';
        }

        return {'accessToken': accessToken, 'refreshToken': refreshToken};
      }

      throw 'Falha ao verificar: código HTTP ${response.statusCode}.';
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  Future<void> resendVerificationEmail({required String email}) async {
    try {
      await api.dio.post('/auth/resend-verification', data: {'email': email});
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await api.dio.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  Future<String> verifyResetPasswordCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await api.dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resetToken = response.data['resetToken'];
        if (resetToken != null) {
          return resetToken as String;
        }
      }
      throw 'Token de recuperação inválido ou não retornado.';
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await api.dio.get('/user/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await api.dio.post(
        '/auth/reset-password',
        data: {'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $resetToken'}),
      );
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }
}
