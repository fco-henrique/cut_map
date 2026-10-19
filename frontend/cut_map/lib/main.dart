import 'package:cut_map/app.dart';
import 'package:cut_map/common/routes/app_router.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  runApp(App(router: createAppRouter(locator<AuthManager>())));
}
