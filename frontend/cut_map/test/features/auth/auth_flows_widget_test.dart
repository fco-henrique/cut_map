import 'package:cut_map/app.dart';
import 'package:cut_map/common/routes/app_router.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/common/widgets/custom_notification_button.dart';
import 'package:cut_map/core/network/api_client.dart';
import 'package:cut_map/core/services/barbershop_service.dart';
import 'package:cut_map/core/services/location_service.dart';
import 'package:cut_map/features/auth/controllers/change_password_controller.dart';
import 'package:cut_map/features/auth/controllers/send_email_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_in_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_up_controller.dart';
import 'package:cut_map/features/auth/controllers/update_password_controller.dart';
import 'package:cut_map/features/auth/controllers/verify_email_controller.dart';
import 'package:cut_map/features/auth/screens/change_password_screen.dart';
import 'package:cut_map/features/auth/screens/send_email_screen.dart';
import 'package:cut_map/features/auth/screens/sign_in_screen.dart';
import 'package:cut_map/features/auth/screens/sign_up_screen.dart';
import 'package:cut_map/features/auth/screens/update_password_screen.dart';
import 'package:cut_map/features/auth/screens/verify_email_screen.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/barbershops/controllers/barbershops_controller.dart';
import 'package:cut_map/features/home/controllers/home_controller.dart';
import 'package:cut_map/features/home/screens/home_screen.dart';
import 'package:cut_map/features/onboarding/services/onboarding_manager.dart';
import 'package:cut_map/features/profile/screens/profile_screen.dart';
import 'package:cut_map/locator.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:cut_map/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../onboarding/onboarding_flow_test.dart';
import 'auth_manager_test.dart';

class _ConfigurableAuthService extends AuthService {
  Future<void> Function(String name, String email, String password)? onSignUp;
  Future<Map<String, String>> Function(String email, String password)? onSignIn;
  Future<void> Function(String email)? onForgotPassword;
  Future<String> Function(String email, String code)? onVerifyResetCode;
  Future<void> Function(String resetToken, String newPassword)? onResetPassword;
  Future<UserModel> Function(
    String userId,
    String currentPassword,
    String newPassword,
  )?
  onUpdatePassword;
  Future<UserModel> Function()? onGetCurrentUser;
  Future<void> Function(String refreshToken)? onLogout;

  int signUpCalls = 0;
  int logoutCalls = 0;

  _ConfigurableAuthService()
    : super(api: ApiClient(storage: InMemoryTokenStorage()));

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    if (onSignUp != null) {
      await onSignUp!(name, email, password);
    }
  }

  @override
  Future<Map<String, String>> signIn({
    required String email,
    required String password,
  }) async {
    if (onSignIn != null) {
      return onSignIn!(email, password);
    }
    return {'accessToken': 'access-1', 'refreshToken': 'refresh-1'};
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    if (onForgotPassword != null) {
      await onForgotPassword!(email);
    }
  }

  @override
  Future<String> verifyResetPasswordCode({
    required String email,
    required String code,
  }) async {
    if (onVerifyResetCode != null) {
      return onVerifyResetCode!(email, code);
    }
    return 'reset-token-123';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    if (onResetPassword != null) {
      await onResetPassword!(resetToken, newPassword);
    }
  }

  @override
  Future<UserModel> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (onUpdatePassword != null) {
      return onUpdatePassword!(userId, currentPassword, newPassword);
    }
    return UserModel(id: userId, name: 'Ana', email: 'ana@cutmap.dev');
  }

  @override
  Future<UserModel> getCurrentUser() async {
    if (onGetCurrentUser != null) {
      return onGetCurrentUser!();
    }
    return UserModel(id: 'u1', name: 'Ana', email: 'ana@cutmap.dev');
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls++;
    if (onLogout != null) {
      await onLogout!(refreshToken);
    }
  }
}

class _StubBarbershopService extends BarbershopService {
  _StubBarbershopService()
    : super(api: ApiClient(storage: InMemoryTokenStorage()));

  @override
  Future<List<BarbershopModel>> fetchMyBarbershops() async => const [];

  @override
  Future<List<BarbershopModel>> fetchAllBarbershops({
    String? sortBy,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 10,
  }) async => const [];
}

class _StubLocationService extends LocationService {
  @override
  Future<LatLng> getUserLocation() async => const LatLng(-23.55, -46.63);

  @override
  Future<LatLng?> getUserLocationOrNull() async => null;
}

void main() {
  late _ConfigurableAuthService authService;
  late InMemoryTokenStorage tokenStorage;
  late AuthManager authManager;
  late OnboardingManager onboardingManager;

  Future<void> setupDeps({bool loggedIn = false}) async {
    await locator.reset();
    authService = _ConfigurableAuthService();
    tokenStorage = InMemoryTokenStorage(
      accessToken: loggedIn ? 'access-1' : null,
      refreshToken: loggedIn ? 'refresh-1' : null,
    );
    authManager = AuthManager(
      storage: tokenStorage,
      authService: authService,
      autoInitialize: false,
    );
    await authManager.initialize();

    onboardingManager = OnboardingManager(
      storage: InMemoryOnboardingStorage(seen: true),
      autoInitialize: false,
    );
    await onboardingManager.initialize();

    final barbershopService = _StubBarbershopService();
    locator.registerSingleton<AuthManager>(authManager);
    locator.registerSingleton<OnboardingManager>(onboardingManager);
    locator.registerFactory(
      () => SignUpScreenController(authService: authService),
    );
    locator.registerFactory(
      () => SignInScreenController(
        authService: authService,
        authManager: authManager,
      ),
    );
    locator.registerFactory(
      () => SendEmailScreenController(authService: authService),
    );
    locator.registerFactory(
      () => VerifyEmailScreenController(
        authService: authService,
        authManager: authManager,
      ),
    );
    locator.registerFactory(
      () => ChangePasswordScreenController(
        authService: authService,
        authManager: authManager,
      ),
    );
    locator.registerFactory(
      () => UpdatePasswordController(
        authService: authService,
        authManager: authManager,
      ),
    );
    locator.registerFactory(
      () => HomeScreenController(
        barbershopService: barbershopService,
        locationService: _StubLocationService(),
      ),
    );
    locator.registerFactory(
      () => BarbershopsController(barbershopService: barbershopService),
    );
  }

  tearDown(() async {
    await locator.reset();
  });

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> dismissSnackbar(WidgetTester tester) async {
    final closeButton = find.byIcon(Icons.close);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();
    }
  }

  group('Cadastro integrado (#7)', () {
    testWidgets('bloqueia dados inválidos e exibe erro de e-mail duplicado antes do sucesso', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await setupDeps();
      final router = createAppRouter(
        authManager,
        onboardingManager,
        initialLocation: NamedRoutes.signUp,
      );

      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);

      // Submissão vazia bloqueia localmente
      await tester.ensureVisible(find.text('Cria Conta'));
      await tester.tap(find.text('Cria Conta'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail é obrigatório'), findsOneWidget);
      expect(authService.signUpCalls, 0);

      // Preenche dados válidos, mas senha fraca
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ana Silva');
      await tester.enterText(fields.at(1), 'ana@cutmap.dev');
      await tester.enterText(fields.at(2), '1234567');
      await tester.enterText(fields.at(3), '1234567');
      await tester.ensureVisible(find.text('Cria Conta'));
      await tester.tap(find.text('Cria Conta'));
      await tester.pumpAndSettle();
      expect(find.text('A senha deve ter pelo menos 8 caracteres'), findsOneWidget);
      expect(authService.signUpCalls, 0);

      // Simula erro 409 de e-mail duplicado
      authService.onSignUp = (_, __, ___) async =>
          throw 'Email já está cadastrado.';
      await tester.enterText(fields.at(2), 'Senha#2026');
      await tester.enterText(fields.at(3), 'Senha#2026');
      await tester.ensureVisible(find.text('Cria Conta'));
      await tester.tap(find.text('Cria Conta'));
      await tester.pumpAndSettle();
      expect(authService.signUpCalls, 1);
      expect(find.text('Email já está cadastrado.'), findsOneWidget);
      await dismissSnackbar(tester);

      // Simula cadastro válido e navegação para verificação
      authService.onSignUp = (_, __, ___) async {};
      await tester.ensureVisible(find.text('Cria Conta'));
      await tester.tap(find.text('Cria Conta'));
      await tester.pumpAndSettle();
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });
  });

  group('Login integrado (#8)', () {
    testWidgets('rejeita credenciais inválidas e autentica credenciais válidas', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await setupDeps();
      final router = createAppRouter(authManager, onboardingManager);

      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ana@cutmap.dev');
      await tester.enterText(fields.at(1), 'errada');

      authService.onSignIn = (_, __) async => throw 'Credenciais inválidas';
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Credenciais inválidas'), findsOneWidget);
      expect(authManager.isLoggedIn, isFalse);
      await dismissSnackbar(tester);

      authService.onSignIn = (_, __) async => {
        'accessToken': 'valid-access',
        'refreshToken': 'valid-refresh',
      };
      await tester.enterText(fields.at(1), 'Senha#2026');
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(authManager.isLoggedIn, isTrue);
      expect(find.text('Próximo agendamento'), findsOneWidget);
    });
  });

  group('Logout na interface (#9)', () {
    testWidgets('notificação na Home não encerra sessão e botão Sair no Perfil faz logout mesmo offline', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await setupDeps(loggedIn: true);
      final router = createAppRouter(authManager, onboardingManager);

      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Tocar no botão de notificação não faz logout
      await tester.tap(find.byType(CustomNotificationButton));
      await tester.pumpAndSettle();
      expect(authManager.isLoggedIn, isTrue);
      expect(authService.logoutCalls, 0);
      await dismissSnackbar(tester);

      // Vai para a aba Perfil e aciona "Sair da conta" com falha de rede simulada
      authService.onLogout = (_) async => throw Exception('offline');
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();

      expect(authService.logoutCalls, 1);
      expect(authManager.isLoggedIn, isFalse);
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('Recuperação de senha (#10)', () {
    testWidgets('percorre solicitação, código inválido/válido e redefinição forte', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await setupDeps();
      final router = createAppRouter(
        authManager,
        onboardingManager,
        initialLocation: NamedRoutes.sendEmail,
      );

      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(SendEmailScreen), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'ana@cutmap.dev');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailScreen), findsOneWidget);

      // Código inválido exibe erro
      authService.onVerifyResetCode = (_, __) async =>
          throw 'Código inválido ou expirado.';
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      expect(find.text('Código inválido ou expirado.'), findsOneWidget);
      await dismissSnackbar(tester);

      // Código válido leva à tela de redefinição
      authService.onVerifyResetCode = (_, __) async => 'reset-token-ok';
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);

      String? capturedToken;
      String? capturedPassword;
      authService.onResetPassword = (token, pwd) async {
        capturedToken = token;
        capturedPassword = pwd;
      };

      final pwdFields = find.byType(TextFormField);
      await tester.enterText(pwdFields.at(0), 'NovaSenha#2026');
      await tester.enterText(pwdFields.at(1), 'NovaSenha#2026');
      await tester.ensureVisible(find.text('Alterar senha'));
      await tester.tap(find.text('Alterar senha'));
      await tester.pumpAndSettle();

      expect(capturedToken, 'reset-token-ok');
      expect(capturedPassword, 'NovaSenha#2026');
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('Alteração de senha autenticada (#11)', () {
    testWidgets('valida senha atual incorreta, nova senha e preserva sessão ao concluir', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await setupDeps(loggedIn: true);
      final router = createAppRouter(authManager, onboardingManager);

      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alterar senha'));
      await tester.pumpAndSettle();

      expect(find.byType(UpdatePasswordScreen), findsOneWidget);

      // Senha atual incorreta (403)
      authService.onUpdatePassword = (_, __, ___) async =>
          throw 'Senha atual incorreta.';

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Errada123!');
      await tester.enterText(fields.at(1), 'NovaSenha#2026');
      await tester.enterText(fields.at(2), 'NovaSenha#2026');
      await tester.ensureVisible(find.text('Salvar nova senha'));
      await tester.tap(find.text('Salvar nova senha'));
      await tester.pumpAndSettle();

      expect(find.text('Senha atual incorreta.'), findsOneWidget);
      expect(authManager.isLoggedIn, isTrue);
      await dismissSnackbar(tester);

      // Sucesso preserva sessão e retorna ao Perfil
      String? updatedUserId;
      String? sentCurrentPassword;
      String? sentNewPassword;
      authService.onUpdatePassword = (userId, current, next) async {
        updatedUserId = userId;
        sentCurrentPassword = current;
        sentNewPassword = next;
        return UserModel(id: userId, name: 'Ana', email: 'ana@cutmap.dev');
      };

      await tester.enterText(fields.at(0), 'Atual#2025');
      await tester.ensureVisible(find.text('Salvar nova senha'));
      await tester.tap(find.text('Salvar nova senha'));
      await tester.pumpAndSettle();

      expect(updatedUserId, 'u1');
      expect(sentCurrentPassword, 'Atual#2025');
      expect(sentNewPassword, 'NovaSenha#2026');
      expect(authManager.isLoggedIn, isTrue);
      expect(authService.logoutCalls, 0);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
