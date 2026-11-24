import 'package:cut_map/core/network/api_error_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException buildResponseError(int statusCode, dynamic data) {
    final options = RequestOptions(path: '/test');
    return DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: statusCode,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test('formata HTTP 400 com message como array de strings', () {
    final err = buildResponseError(400, {
      'statusCode': 400,
      'message': ['Senha fraca', 'E-mail inválido'],
      'error': 'Bad Request',
    });

    expect(ApiErrorHandler.handleError(err), 'Senha fraca\nE-mail inválido');
  });

  test('formata HTTP 409 de e-mail duplicado', () {
    final err = buildResponseError(409, {
      'statusCode': 409,
      'message': 'Email já está cadastrado.',
      'error': 'Conflict',
    });

    expect(ApiErrorHandler.handleError(err), 'Email já está cadastrado.');
  });

  test('formata HTTP 403 de senha atual incorreta', () {
    final err = buildResponseError(403, {
      'statusCode': 403,
      'message': 'Senha atual incorreta.',
      'error': 'Forbidden',
    });

    expect(ApiErrorHandler.handleError(err), 'Senha atual incorreta.');
  });

  test('retorna mensagem amigável em falha de conexão', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );

    expect(
      ApiErrorHandler.handleError(err),
      contains('Servidor demorou a responder ou está offline'),
    );
  });
}
