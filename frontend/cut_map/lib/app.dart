import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/features/splash/splash_screen.dart';
import 'package:cut_map/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Sizes.init(context);

    return MaterialApp(
      initialRoute: NamedRoutes.splash,
      routes: {
        NamedRoutes.splash: (context) => SplashScreen(),
        NamedRoutes.welcome: (context) => WelcomeScreen(),
      },
    );
  }
}
