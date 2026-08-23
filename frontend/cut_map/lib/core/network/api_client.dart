import 'package:cut_map/core/storage/token_storage.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage storage;

  final Dio _refreshDio = Dio(BaseOptions(baseUrl: 'http://192.168.0.3:3000'));

  ApiClient({required this.storage}) : dio = Dio() {
    dio.options = BaseOptions(baseUrl: 'http://192.168.0.3:3000');

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

              if (refreshResponse.statusCode == 200 ||
                  refreshResponse.statusCode == 201) {
                final newAccessToken = refreshResponse.data['accessToken'];
                final newRefreshToken = refreshResponse.data['refreshToken'];

                await storage.saveTokens(newAccessToken, newRefreshToken);

                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final retryResponse = await dio.fetch(e.requestOptions);

                return handler.resolve(retryResponse);
              }
            } catch (refreshError) {
              // Resolvido aqui, no momento do erro — não no construtor.
              // É isso que quebra o ciclo ApiClient -> AuthManager -> AuthService -> ApiClient.
              await locator<AuthManager>().logout();
              return handler.next(e);
            }
          }

          return handler.next(e);
        },
      ),
    );
  }
}