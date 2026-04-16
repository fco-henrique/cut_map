import 'dart:developer';

import 'package:cut_map/services/api_client.dart';
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
    log(
      "Os dados chegaram no service name: $name email: $email password: $password",
    );
    try {
      final response = await api.dio.post(
        '/user',
        data: {'name': name, 'email': email, 'password': password},
      );

      log("Usuário criado com sucesso: ${response.data}");
    } on DioException catch (e) {
      log("Erro do servidor: ${e.response?.data}");

      String errorMessage = 'Ocorreu um erro de comunicação com o servidor.';

      if (e.response?.data != null) {
        var responseData = e.response!.data;

        if (responseData is Map && responseData.containsKey('detail')) {
          errorMessage = responseData['detail'];
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      throw Exception(errorMessage);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await api.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("accessToken: ${response.data['accessToken']}");
        log("refreshToken: ${response.data['refreshToken']}");
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorDetail = e.response?.data['message'] ?? e.response?.data['detail'];
        throw errorDetail ?? 'Credenciais inválidas';
      }
      throw 'Não foi possível conectar ao servidor. Verifique sua conexão.';
    } catch (e) {
      throw 'Ocorreu um erro inesperado: ${e.toString()}';
    }
}
}
