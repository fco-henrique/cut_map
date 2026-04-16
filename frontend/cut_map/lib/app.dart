import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/features/auth/screens/sign_in_screen.dart';
import 'package:cut_map/features/auth/screens/sign_up_screen.dart';
import 'package:cut_map/features/auth/screens/verify_email_screen.dart';
import 'package:cut_map/features/splash/splash_screen.dart';
import 'package:cut_map/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Sizes.init(context);

    return MaterialApp.router(
      routerConfig: _router, // Aqui conectamos o GoRouter
      debugShowCheckedModeBanner: false,
    );
  }
}

final _router = GoRouter(
  initialLocation: NamedRoutes.signIn,
  routes: [
    GoRoute(
      path: NamedRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: NamedRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: NamedRoutes.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: NamedRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: NamedRoutes.emailVerify,
      builder: (context, state) => const VerifyEmailScreen(),
    ),
  ],
);
