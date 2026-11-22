import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String handleError(dynamic e, {String? fallbackMessage}) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Servidor demorou a responder ou está offline. Verifique sua conexão.';
      }

      String errorMessage =
          fallbackMessage ?? 'Ocorreu um erro de comunicação com o servidor.';

      if (e.response?.data != null) {
        final responseData = e.response!.data;

        if (responseData is Map) {
          if (responseData.containsKey('message')) {
            final messageData = responseData['message'];

            if (messageData is List && messageData.isNotEmpty) {
              final messages = messageData
                  .map((item) => item.toString().trim())
                  .where((item) => item.isNotEmpty)
                  .toList();
              if (messages.isNotEmpty) {
                errorMessage = messages.join('\n');
              }
            } else if (messageData != null &&
                messageData.toString().trim().isNotEmpty) {
              errorMessage = messageData.toString();
            }
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
        } else if (responseData is String && responseData.trim().isNotEmpty) {
          errorMessage = responseData;
        }
      }

      return errorMessage;
    }

    return 'Ocorreu um erro inesperado: ${e.toString()}';
  }
}
