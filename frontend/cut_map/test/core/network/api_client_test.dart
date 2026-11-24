import 'dart:convert';
import 'dart:typed_data';

import 'package:cut_map/core/network/api_client.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/auth_manager_test.dart';

typedef _AdapterHandler = Future<ResponseBody> Function(RequestOptions options);

class _StubHttpClientAdapter implements HttpClientAdapter {
  final _AdapterHandler _handler;

  _StubHttpClientAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  int statusCode,
  Object body, {
  Map<String, List<String>> headers = const {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: headers,
  );
}

void main() {
  group('ApiClient refresh de sessão', () {
    test(
      'renova tokens e repete requisição quando /auth/refresh retorna 200',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired-access',
          refreshToken: 'valid-refresh',
        );
        var sessionExpiredCalls = 0;

        final dio = Dio();
        var apiCalls = 0;
        dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          apiCalls++;
          if (apiCalls == 1) {
            expect(options.headers['Authorization'], 'Bearer expired-access');
            return _jsonResponse(401, {'message': 'Token expirado'});
          }
          expect(options.headers['Authorization'], 'Bearer new-access');
          return _jsonResponse(200, {'ok': true});
        });

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          expect(options.path, '/auth/refresh');
          expect(options.data, {'refreshToken': 'valid-refresh'});
          return _jsonResponse(200, {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
          });
        });

        final client = ApiClient(
          storage: storage,
          dio: dio,
          refreshDio: refreshDio,
          onSessionExpired: () async {
            sessionExpiredCalls++;
          },
        );

        final response = await client.dio.get('/barbershops');

        expect(response.statusCode, 200);
        expect(response.data, {'ok': true});
        expect(storage.accessToken, 'new-access');
        expect(storage.refreshToken, 'new-refresh');
        expect(storage.deleteCalled, isFalse);
        expect(sessionExpiredCalls, 0);
      },
    );

    test(
      'preserva sessão local quando /auth/refresh falha por erro transitório de rede',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired-access',
          refreshToken: 'valid-refresh',
        );
        var sessionExpiredCalls = 0;

        final dio = Dio();
        dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(401, {'message': 'Token expirado'});
        });

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Sem internet',
          );
        });

        final client = ApiClient(
          storage: storage,
          dio: dio,
          refreshDio: refreshDio,
          onSessionExpired: () async {
            sessionExpiredCalls++;
          },
        );

        await expectLater(
          client.dio.get('/barbershops'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.connectionError,
            ),
          ),
        );

        expect(sessionExpiredCalls, 0);
        expect(storage.deleteCalled, isFalse);
        expect(storage.accessToken, 'expired-access');
        expect(storage.refreshToken, 'valid-refresh');
      },
    );

    test(
      'preserva sessão local quando /auth/refresh retorna HTTP 5xx',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired-access',
          refreshToken: 'valid-refresh',
        );
        var sessionExpiredCalls = 0;

        final dio = Dio();
        dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(401, {'message': 'Token expirado'});
        });

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(503, {'message': 'Serviço indisponível'});
        });

        final client = ApiClient(
          storage: storage,
          dio: dio,
          refreshDio: refreshDio,
          onSessionExpired: () async {
            sessionExpiredCalls++;
          },
        );

        await expectLater(
          client.dio.get('/barbershops'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              503,
            ),
          ),
        );

        expect(sessionExpiredCalls, 0);
        expect(storage.deleteCalled, isFalse);
        expect(storage.accessToken, 'expired-access');
        expect(storage.refreshToken, 'valid-refresh');
      },
    );

    test(
      'preserva sessão local quando /auth/refresh retorna payload inválido (200 malformado)',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired-access',
          refreshToken: 'valid-refresh',
        );
        var sessionExpiredCalls = 0;

        final dio = Dio();
        dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(401, {'message': 'Token expirado'});
        });

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return ResponseBody.fromString('<html>captive portal</html>', 200);
        });

        final client = ApiClient(
          storage: storage,
          dio: dio,
          refreshDio: refreshDio,
          onSessionExpired: () async {
            sessionExpiredCalls++;
          },
        );

        await expectLater(
          client.dio.get('/barbershops'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              isNull,
            ),
          ),
        );

        expect(sessionExpiredCalls, 0);
        expect(storage.deleteCalled, isFalse);
        expect(storage.accessToken, 'expired-access');
        expect(storage.refreshToken, 'valid-refresh');
      },
    );

    for (final statusCode in [401, 403]) {
      test(
        'expira sessão quando /auth/refresh confirma token inválido com HTTP $statusCode',
        () async {
          final storage = InMemoryTokenStorage(
            accessToken: 'expired-access',
            refreshToken: 'revoked-refresh',
          );
          var sessionExpiredCalls = 0;

          final dio = Dio();
          dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
            return _jsonResponse(401, {'message': 'Token expirado'});
          });

          final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
          refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
            return _jsonResponse(statusCode, {'message': 'Refresh inválido'});
          });

          final client = ApiClient(
            storage: storage,
            dio: dio,
            refreshDio: refreshDio,
            onSessionExpired: () async {
              sessionExpiredCalls++;
              await storage.deleteTokens();
            },
          );

          await expectLater(
            client.dio.get('/barbershops'),
            throwsA(
              isA<DioException>().having(
                (e) => e.response?.statusCode,
                'statusCode',
                statusCode,
              ),
            ),
          );

          expect(sessionExpiredCalls, 1);
          expect(storage.deleteCalled, isTrue);
          expect(storage.accessToken, isNull);
          expect(storage.refreshToken, isNull);
        },
      );
    }

    test(
      'AuthManager preserva tokens no startup quando /user/me retorna 401 e refresh falha com 503',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired-access',
          refreshToken: 'valid-refresh',
        );

        final dio = Dio();
        dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(401, {'message': 'Token expirado'});
        });

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(503, {'message': 'Serviço indisponível'});
        });

        late AuthManager manager;
        final client = ApiClient(
          storage: storage,
          dio: dio,
          refreshDio: refreshDio,
          onSessionExpired: () => manager.logout(),
        );
        final authService = AuthService(api: client);
        manager = AuthManager(
          storage: storage,
          authService: authService,
          autoInitialize: false,
        );

        await manager.initialize();

        expect(manager.isInitialized, isTrue);
        expect(manager.isLoggedIn, isFalse);
        expect(storage.deleteCalled, isFalse);
        expect(storage.accessToken, 'expired-access');
        expect(storage.refreshToken, 'valid-refresh');
      },
    );

    test(
      'AuthManager revoga tokens no startup quando /user/me retorna 401 e refresh confirma 401',
      () async {
        final storage = InMemoryTokenStorage(
          accessToken: 'expired-access',
          refreshToken: 'revoked-refresh',
        );

        final dio = Dio();
        dio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          if (options.path == '/auth/logout') {
            return _jsonResponse(200, {'message': 'Sessão encerrada.'});
          }
          return _jsonResponse(401, {'message': 'Token expirado'});
        });

        final refreshDio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
        refreshDio.httpClientAdapter = _StubHttpClientAdapter((options) async {
          return _jsonResponse(401, {'message': 'Refresh token inválido.'});
        });

        late AuthManager manager;
        final client = ApiClient(
          storage: storage,
          dio: dio,
          refreshDio: refreshDio,
          onSessionExpired: () => manager.logout(),
        );
        final authService = AuthService(api: client);
        manager = AuthManager(
          storage: storage,
          authService: authService,
          autoInitialize: false,
        );

        await manager.initialize();

        expect(manager.isInitialized, isTrue);
        expect(manager.isLoggedIn, isFalse);
        expect(storage.deleteCalled, isTrue);
        expect(storage.accessToken, isNull);
        expect(storage.refreshToken, isNull);
      },
    );
  });
}
