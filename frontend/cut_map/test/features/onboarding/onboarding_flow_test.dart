import 'package:cut_map/app.dart';
import 'package:cut_map/common/routes/app_router.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/features/auth/controllers/send_email_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_in_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_up_controller.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/barbershops/controllers/barbershops_controller.dart';
import 'package:cut_map/features/home/controllers/home_controller.dart';
import 'package:cut_map/features/onboarding/screens/onboarding_screen.dart';
import 'package:cut_map/features/onboarding/services/onboarding_manager.dart';
import 'package:cut_map/features/onboarding/services/onboarding_storage.dart';
import 'package:cut_map/locator.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:cut_map/core/services/barbershop_service.dart';
import 'package:cut_map/core/services/location_service.dart';
import 'package:cut_map/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../auth/auth_manager_test.dart';

class InMemoryOnboardingStorage implements OnboardingStorage {
  bool seen;

  InMemoryOnboardingStorage({this.seen = false});

  @override
  Future<bool> hasSeenOnboarding() async => seen;

  @override
  Future<void> markOnboardingAsSeen() async {
    seen = true;
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
  setUp(() async {
    await locator.reset();
  });

  tearDown(() async {
    await locator.reset();
  });

  void registerRouterTestDependencies(AuthManager authManager) {
    final authService = FakeAuthService();
    final barbershopService = _StubBarbershopService();
    locator.registerSingleton<AuthManager>(authManager);
    locator.registerFactory(
      () => SignInScreenController(
        authService: authService,
        authManager: authManager,
      ),
    );
    locator.registerFactory(
      () => SignUpScreenController(authService: authService),
    );
    locator.registerFactory(
      () => SendEmailScreenController(authService: authService),
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

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('OnboardingScreen widget (#12)', () {
    testWidgets('exibe as três etapas e Pular leva para login com acesso a cadastro', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = InMemoryTokenStorage();
      final authManager = AuthManager(
        storage: storage,
        authService: FakeAuthService(),
        autoInitialize: false,
      );
      await authManager.initialize();
      registerRouterTestDependencies(authManager);

      final onboardingStorage = InMemoryOnboardingStorage(seen: false);
      final onboardingManager = OnboardingManager(
        storage: onboardingStorage,
        autoInitialize: false,
      );
      await onboardingManager.initialize();

      final router = createAppRouter(authManager, onboardingManager);
      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Barbearias perto de você'), findsOneWidget);
      expect(
        find.text(
          'Encontre os melhores lugares com base na sua localização, avaliação e distância.',
        ),
        findsOneWidget,
      );
      expect(find.text('cut_map'), findsOneWidget);
      expect(
        tester.getTopRight(find.text('Pular')).dx,
        greaterThan(215),
      );

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(onboardingManager.hasSeenOnboarding, isTrue);
      expect(onboardingStorage.seen, isTrue);
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);

      await tester.ensureVisible(find.text('Criar Conta'));
      await tester.tap(find.text('Criar Conta'));
      await tester.pumpAndSettle();
      expect(find.text('Junte-se a comunidade cut_map'), findsOneWidget);
    });

    testWidgets('avança pelas três etapas até Começar 🚀 e vai ao login', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = InMemoryTokenStorage();
      final authManager = AuthManager(
        storage: storage,
        authService: FakeAuthService(),
        autoInitialize: false,
      );
      await authManager.initialize();
      registerRouterTestDependencies(authManager);

      final onboardingStorage = InMemoryOnboardingStorage(seen: false);
      final onboardingManager = OnboardingManager(
        storage: onboardingStorage,
        autoInitialize: false,
      );
      await onboardingManager.initialize();

      final router = createAppRouter(authManager, onboardingManager);
      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Barbearias perto de você'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Barbearias perto de você')).dx,
        lessThan(40),
      );
      expect(
        tester.getTopRight(find.text('Próximo →')).dx,
        greaterThan(250),
      );

      await tester.tap(find.text('Próximo →'));
      await tester.pumpAndSettle();

      expect(find.text('Agende em poucos passos'), findsOneWidget);
      expect(
        find.text(
          'Escolha o barbeiro, o serviço e o horário ideal. Tudo sem sair do app.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Próximo →'));
      await tester.pumpAndSettle();

      expect(find.text('Avalie e compartilhe'), findsOneWidget);
      expect(
        find.text(
          'Deixe sua opinião, favorite as melhores e ajude outros usuários a encontrar o corte perfeito.',
        ),
        findsOneWidget,
      );
      expect(find.text('Começar 🚀'), findsOneWidget);

      await tester.tap(find.text('Começar 🚀'));
      await tester.pumpAndSettle();

      expect(onboardingManager.hasSeenOnboarding, isTrue);
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    });

    testWidgets(
      'não sofre overflow no rodapé ao redimensionar para 390x844 e em viewport 320x568',
      (tester) async {
        Future<void> verifyViewport(Size size, {Size? initialSize}) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = initialSize ?? size;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final authManager = AuthManager(
            storage: InMemoryTokenStorage(),
            authService: FakeAuthService(),
            autoInitialize: false,
          );
          await authManager.initialize();
          registerRouterTestDependencies(authManager);

          final onboardingStorage = InMemoryOnboardingStorage(seen: false);
          final onboardingManager = OnboardingManager(
            storage: onboardingStorage,
            autoInitialize: false,
          );
          await onboardingManager.initialize();

          final router = createAppRouter(authManager, onboardingManager);
          await tester.pumpWidget(App(router: router));
          await tester.pumpAndSettle();

          if (initialSize != null) {
            tester.view.physicalSize = size;
            await tester.pumpAndSettle();
          }

          expect(tester.takeException(), isNull);
          final nextButton = find.widgetWithText(ElevatedButton, 'Próximo →');
          expect(nextButton, findsOneWidget);
          expect(
            tester.getTopRight(nextButton).dx,
            lessThanOrEqualTo(size.width),
          );

          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Agende em poucos passos'), findsOneWidget);

          await tester.tap(find.widgetWithText(ElevatedButton, 'Próximo →'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Avalie e compartilhe'), findsOneWidget);

          final startButton = find.widgetWithText(ElevatedButton, 'Começar 🚀');
          expect(startButton, findsOneWidget);
          expect(
            tester.getTopRight(startButton).dx,
            lessThanOrEqualTo(size.width),
          );

          await tester.tap(startButton);
          await tester.pumpAndSettle();
          expect(onboardingManager.hasSeenOnboarding, isTrue);
          expect(find.text('Bem-vindo de volta!'), findsOneWidget);
        }

        // Simula carregamento inicial em tela desktop seguido de resize para 390x844
        await verifyViewport(
          const Size(390, 844),
          initialSize: const Size(1024, 900),
        );

        await locator.reset();

        // Verifica viewport compacta 320x568 em todas as 3 etapas
        await verifyViewport(const Size(320, 568));
      },
    );
  });

  group('Proteção de rotas e redirecionamentos (#8, #9, #12)', () {
    testWidgets('redireciona rota protegida para login quando sem sessão e após logout não repete onboarding', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = InMemoryTokenStorage(
        accessToken: 'valid-access',
        refreshToken: 'valid-refresh',
      );
      final authManager = AuthManager(
        storage: storage,
        authService: FakeAuthService(),
        autoInitialize: false,
      );
      await authManager.initialize();
      registerRouterTestDependencies(authManager);

      final onboardingManager = OnboardingManager(
        storage: InMemoryOnboardingStorage(seen: true),
        autoInitialize: false,
      );
      await onboardingManager.initialize();

      final router = createAppRouter(authManager, onboardingManager);
      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      // Sessão válida vai para MainScreen
      expect(find.text('Próximo agendamento'), findsOneWidget);

      // Logout redireciona direto para SignIn sem repetir onboarding
      await authManager.logout();
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      // Tentativa de acessar rota protegida sem sessão volta para SignIn
      router.go(NamedRoutes.main);
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);

      router.go(NamedRoutes.profileChangePassword);
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    });

    testWidgets('rotas públicas permanecem acessíveis sem sessão após onboarding', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final authManager = AuthManager(
        storage: InMemoryTokenStorage(),
        authService: FakeAuthService(),
        autoInitialize: false,
      );
      await authManager.initialize();
      registerRouterTestDependencies(authManager);

      final onboardingManager = OnboardingManager(
        storage: InMemoryOnboardingStorage(seen: true),
        autoInitialize: false,
      );
      await onboardingManager.initialize();

      final router = createAppRouter(authManager, onboardingManager);
      await tester.pumpWidget(App(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo de volta!'), findsOneWidget);

      router.go(NamedRoutes.signUp);
      await tester.pumpAndSettle();
      expect(find.text('Junte-se a comunidade cut_map'), findsOneWidget);

      router.go(NamedRoutes.sendEmail);
      await tester.pumpAndSettle();
      expect(find.text('Digite seu e-mail'), findsOneWidget);
    });
  });
}
