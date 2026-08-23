import 'package:cut_map/core/services/barbershop_service.dart';
import 'package:cut_map/core/services/location_service.dart';
import 'package:cut_map/features/auth/controllers/change_password_controller.dart';
import 'package:cut_map/features/auth/controllers/send_email_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_in_controller.dart';
import 'package:cut_map/features/auth/controllers/sign_up_controller.dart';
import 'package:cut_map/features/auth/controllers/verify_email_controller.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/core/network/api_client.dart';
import 'package:cut_map/core/storage/token_storage.dart';
import 'package:cut_map/features/home/controllers/home_controller.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // SERVIÇOS
  locator.registerLazySingleton(() => TokenStorage());
  locator.registerLazySingleton(
    () => ApiClient(storage: locator<TokenStorage>()),
  );
  locator.registerLazySingleton(
    () => AuthManager(
      storage: locator<TokenStorage>(),
      authService: locator<AuthService>(),
    ),
  );
  locator.registerLazySingleton(() => AuthService(api: locator<ApiClient>()));
  locator.registerLazySingleton(
    () => BarbershopService(api: locator<ApiClient>()),
  );
  locator.registerLazySingleton(() => LocationService());

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
  locator.registerFactory(
    () => SendEmailScreenController(authService: locator<AuthService>()),
  );
  locator.registerFactory(
    () => ChangePasswordScreenController(authService: locator<AuthService>()),
  );
  locator.registerFactory(
    () => HomeScreenController(
      barbershopService: locator<BarbershopService>(),
      locationService: locator<LocationService>(),
    ),
  );
}
