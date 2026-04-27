import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/features/auth/screens/sign_in_screen.dart';
import 'package:cut_map/features/auth/screens/sign_up_screen.dart';
// import 'package:cut_map/features/auth/screens/sign_up_screen.dart';
import 'package:cut_map/features/auth/screens/verify_email_screen.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/splash/splash_screen.dart';
import 'package:cut_map/features/welcome/welcome_screen.dart';
import 'package:cut_map/locator.dart';
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

final authManager = locator.get<AuthManager>();

final _router = GoRouter(
  initialLocation: NamedRoutes.splash,
  refreshListenable: authManager,
  redirect: (context, state) {
    if (!authManager.isInitialized) {
      return NamedRoutes.splash;
    }

    final isLoggedIn = authManager.isLoggedIn;

    final publicRoutes = [
      NamedRoutes.signIn,
      NamedRoutes.signUp,
      NamedRoutes.emailVerify,
    ];

    final isGoingToPublicRoute = publicRoutes.contains(state.matchedLocation);

    if (!isLoggedIn && !isGoingToPublicRoute) {
      return NamedRoutes.signIn;
    }

    final isGoingToLoginOrSplash =
        state.matchedLocation == NamedRoutes.signIn ||
        state.matchedLocation == NamedRoutes.splash;

    if (isLoggedIn && isGoingToLoginOrSplash) {
      return NamedRoutes.welcome;
    }

    return null;
  },
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
      path: NamedRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: NamedRoutes.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: NamedRoutes.emailVerify,
      name: NamedRoutes.emailVerify,
      builder: (context, state) {
        final email = state.extra as String; 
        return VerifyEmailScreen(email: email);
      }
    ),
  ],
);


// GoRoute(
    //   path: '/welcome',
    //   name: NamedRoutes.welcome,
    //   pageBuilder: (context, state) {
    //     return CustomTransitionPage(
    //       key: state.pageKey,
    //       child: const WelcomeScreen(),
    //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //         return FadeTransition(
    //           opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    //           child: child,
    //         );
    //       },
    //     );
    //   },
    // ),
    // GoRoute(
    //   path: NamedRoutes.signUp,
    //   builder: (context, state) => const SignUpScreen(),
    // ),