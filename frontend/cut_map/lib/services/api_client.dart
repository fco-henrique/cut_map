import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/services/token_storage.dart';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage storage;
  final AuthManager authManager;

  final Dio _refreshDio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));

  ApiClient({required this.storage, required this.authManager}) : dio = Dio() {
    dio.options = BaseOptions(baseUrl: 'http://10.0.2.2:3000');
    
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            
            final refreshToken = await storage.readRefreshToken();
            
            if (refreshToken == null) {
              return handler.next(e);
            }

            try {
              final refreshResponse = await _refreshDio.post(
                '/auth/refresh', 
                data: {'refreshToken': refreshToken},
              );

              if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
                final newAccessToken = refreshResponse.data['accessToken'];
                final newRefreshToken = refreshResponse.data['refreshToken'];
                
                await storage.saveTokens(newAccessToken, newRefreshToken
                );

                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                final retryResponse = await dio.fetch(e.requestOptions);
                
                return handler.resolve(retryResponse);
              }
            } catch (refreshError) {
              await authManager.logout(); 
              return handler.next(e);
            }
          }

          return handler.next(e);
        },
      ),
    );
  }
}