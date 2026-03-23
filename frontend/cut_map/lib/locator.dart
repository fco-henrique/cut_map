import 'package:cut_map/services/api_client.dart';
import 'package:cut_map/services/token_storage.dart';
import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // SERVIÇOS 
  locator.registerLazySingleton(() => TokenStorage());
  locator.registerLazySingleton(() => ApiClient(storage: locator<TokenStorage>()));

  // CONTROLLERS
}