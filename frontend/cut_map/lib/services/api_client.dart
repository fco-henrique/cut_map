import 'package:cut_map/services/token_storage.dart';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage storage;

  ApiClient({required this.storage}) : dio = Dio() {
    dio.options = BaseOptions(baseUrl: 'http://10.0.2.2:8000');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static Future<ApiClient> create() async {
    final storage = TokenStorage();
    return ApiClient(storage: storage);
  }
}