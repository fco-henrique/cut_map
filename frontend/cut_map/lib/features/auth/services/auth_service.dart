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
    try {
      await api.dio.post(
        '/user',
        data: {'name': name, 'email': email, 'password': password},
      );

    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'Servidor demorou a responder ou está offline. Verifique sua conexão.';
      }

      String errorMessage = 'Ocorreu um erro de comunicação com o servidor.';

      if (e.response?.data != null) {
        var responseData = e.response!.data;

        if (responseData is Map) {
          if (responseData.containsKey('message')) {
            var messageData = responseData['message'];

            if (messageData is List && messageData.isNotEmpty) {
              errorMessage = messageData.first.toString();
            } else {
              errorMessage = messageData.toString();
            }
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      }

      throw errorMessage;
    } catch (e) {
      throw 'Ocorreu um erro inesperado: ${e.toString()}';
    }
  }

  Future<Map<String, String>> signIn({required String email, required String password}) async {
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

        return {
          'accessToken': accessToken, 
          'refreshToken': refreshToken
        };
      }

      throw 'Falha ao autenticar: código HTTP ${response.statusCode}.';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw 'Servidor demorou a responder ou está offline. Verifique sua conexão.';
      }

      if (e.response != null && e.response?.data != null) {
        final errorDetail =
            e.response?.data['message'] ?? e.response?.data['detail'];
        throw errorDetail ?? 'Credenciais inválidas';
      }

      throw 'Não foi possível conectar ao servidor. Verifique sua conexão.';
    } catch (e) {
      throw 'Ocorreu um erro inesperado: ${e.toString()}';
    }
  }
}
