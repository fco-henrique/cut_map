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

      String errorMessage = fallbackMessage ?? 'Ocorreu um erro de comunicação com o servidor.';

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

      return errorMessage;
    } 
    
    return 'Ocorreu um erro inesperado: ${e.toString()}';
  }
}