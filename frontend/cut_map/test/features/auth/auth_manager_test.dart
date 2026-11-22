import 'package:cut_map/core/network/api_client.dart';
import 'package:cut_map/core/storage/token_storage.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;
  bool deleteCalled = false;

  InMemoryTokenStorage({this.accessToken, this.refreshToken});

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> deleteTokens() async {
    deleteCalled = true;
    accessToken = null;
    refreshToken = null;
  }
}

class FakeAuthService extends AuthService {
  Future<UserModel> Function()? onGetCurrentUser;
  Future<String> Function(String refreshToken)? onRefreshSession;
  Future<void> Function(String refreshToken)? onLogout;
  String? lastLogoutRefreshToken;

  FakeAuthService()
    : super(api: ApiClient(storage: InMemoryTokenStorage()));

  @override
  Future<UserModel> getCurrentUser() async {
    if (onGetCurrentUser != null) {
      return onGetCurrentUser!();
    }
    return UserModel(id: 'u1', name: 'João', email: 'joao@cutmap.dev');
  }

  @override
  Future<String> refreshSession(String refreshToken) async {
    if (onRefreshSession != null) {
      return onRefreshSession!(refreshToken);
    }
    return 'new-access';
  }

  @override
  Future<void> logout(String refreshToken) async {
    lastLogoutRefreshToken = refreshToken;
    if (onLogout != null) {
      await onLogout!(refreshToken);
    }
  }
}

void main() {
  group('AuthManager restauração de sessão (#8)', () {
    test('não autentica quando não há tokens armazenados', () async {
      final storage = InMemoryTokenStorage();
      final authService = FakeAuthService();
      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );

      await manager.initialize();

      expect(manager.isInitialized, isTrue);
      expect(manager.isLoggedIn, isFalse);
      expect(manager.user, isNull);
    });

    test('valida sessão pela API quando tokens armazenados são válidos', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'valid-access',
        refreshToken: 'valid-refresh',
      );
      final authService = FakeAuthService()
        ..onGetCurrentUser = () async =>
            UserModel(id: 'u1', name: 'Carlos', email: 'carlos@cutmap.dev');

      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );

      await manager.initialize();

      expect(manager.isInitialized, isTrue);
      expect(manager.isLoggedIn, isTrue);
      expect(manager.user?.id, 'u1');
      expect(manager.user?.name, 'Carlos');
    });

    test('renova sessão com refreshToken quando accessToken está ausente', () async {
      final storage = InMemoryTokenStorage(refreshToken: 'valid-refresh');
      final authService = FakeAuthService()
        ..onRefreshSession = (refresh) async {
          expect(refresh, 'valid-refresh');
          await storage.saveTokens('refreshed-access', 'refreshed-refresh');
          return 'refreshed-access';
        }
        ..onGetCurrentUser = () async =>
            UserModel(id: 'u2', name: 'Maria', email: 'maria@cutmap.dev');

      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );

      await manager.initialize();

      expect(manager.isLoggedIn, isTrue);
      expect(manager.user?.id, 'u2');
      expect(storage.accessToken, 'refreshed-access');
    });

    test('revoga estado local quando token armazenado é inválido/expirado', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'expired-access',
        refreshToken: 'expired-refresh',
      );
      final authService = FakeAuthService()
        ..onGetCurrentUser = () async =>
            throw const AuthSessionInvalidException('Sessão expirada');

      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );

      await manager.initialize();

      expect(manager.isInitialized, isTrue);
      expect(manager.isLoggedIn, isFalse);
      expect(manager.user, isNull);
      expect(storage.deleteCalled, isTrue);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('não declara sessão válida quando API falha na verificação inicial', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'stale-access',
        refreshToken: 'stale-refresh',
      );
      final authService = FakeAuthService()
        ..onGetCurrentUser = () async => throw 'Servidor offline';

      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );

      await manager.initialize();

      expect(manager.isInitialized, isTrue);
      expect(manager.isLoggedIn, isFalse);
      expect(manager.user, isNull);
    });
  });

  group('AuthManager logout (#9)', () {
    test('chama POST /auth/logout e apaga tokens locais em sucesso', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      final authService = FakeAuthService();
      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );
      await manager.initialize();
      expect(manager.isLoggedIn, isTrue);

      await manager.logout();

      expect(authService.lastLogoutRefreshToken, 'refresh-1');
      expect(storage.deleteCalled, isTrue);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(manager.isLoggedIn, isFalse);
      expect(manager.user, isNull);
    });

    test('apaga tokens e encerra sessão local mesmo com falha de rede no logout', () async {
      final storage = InMemoryTokenStorage(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      final authService = FakeAuthService()
        ..onLogout = (_) async => throw Exception('Falha de rede');

      final manager = AuthManager(
        storage: storage,
        authService: authService,
        autoInitialize: false,
      );
      await manager.initialize();
      expect(manager.isLoggedIn, isTrue);

      await manager.logout();

      expect(authService.lastLogoutRefreshToken, 'refresh-1');
      expect(storage.deleteCalled, isTrue);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(manager.isLoggedIn, isFalse);
      expect(manager.user, isNull);
    });
  });
}
