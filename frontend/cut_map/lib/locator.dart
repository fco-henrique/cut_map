import 'package:cut_map/features/auth/controllers/sign_in_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_up_controller.dart';
import 'package:cut_map/features/auth/controllers/verify_email_controller.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/services/api_client.dart';
import 'package:cut_map/services/token_storage.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // SERVIÇOS
  locator.registerLazySingleton(() => TokenStorage());
  locator.registerLazySingleton(
    () => ApiClient(
      storage: locator<TokenStorage>(),
      authManager: locator<AuthManager>(),
    ),
  );
  locator.registerLazySingleton(
    () => AuthManager(storage: locator<TokenStorage>()),
  );
  locator.registerLazySingleton(
    () => AuthService(
      api: locator<ApiClient>(),
    ),
  );

  // CONTROLLERS
  locator.registerFactory(
    () => SignUpScreenController(authService: locator<AuthService>()),
  );
  locator.registerFactory(
    () => SignInScreenController(authService: locator<AuthService>()),
  );
  locator.registerFactory(
    () => VerifyEmailScreenController(authService: locator<AuthService>()),
  );  
}