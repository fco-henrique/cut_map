import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/features/auth/screens/change_password_screen.dart';
import 'package:cut_map/features/auth/screens/send_email_screen.dart';
import 'package:cut_map/features/auth/screens/sign_in_screen.dart';
import 'package:cut_map/features/auth/screens/sign_up_screen.dart';
import 'package:cut_map/features/auth/screens/verify_email_screen.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/splash/splash_screen.dart';
import 'package:cut_map/features/welcome/welcome_screen.dart';
import 'package:cut_map/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(AuthManager authManager) {
  return GoRouter(
    initialLocation: NamedRoutes.splash,
    refreshListenable: authManager,
    redirect: (context, state) {
      if (!authManager.isInitialized) {
        return NamedRoutes.splash;
      }

      final extra = state.extra;
      if (state.matchedLocation == NamedRoutes.emailVerify &&
          (extra is! VerificationRouteData || extra.email.trim().isEmpty)) {
        return NamedRoutes.signIn;
      }
      if (state.matchedLocation == NamedRoutes.changePassword &&
          (extra is! String || extra.isEmpty)) {
        return NamedRoutes.sendEmail;
      }

      const publicRoutes = {
        NamedRoutes.signIn,
        NamedRoutes.signUp,
        NamedRoutes.emailVerify,
        NamedRoutes.sendEmail,
        NamedRoutes.changePassword,
        NamedRoutes.welcome,
      };

      if (!authManager.isLoggedIn &&
          !publicRoutes.contains(state.matchedLocation)) {
        return NamedRoutes.signIn;
      }

      final isGoingToLoginOrSplash =
          state.matchedLocation == NamedRoutes.signIn ||
          state.matchedLocation == NamedRoutes.splash;

      if (authManager.isLoggedIn && isGoingToLoginOrSplash) {
        return NamedRoutes.main;
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
        name: NamedRoutes.welcome,
        pageBuilder: (context, state) =>
            _transition(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: NamedRoutes.signIn,
        name: NamedRoutes.signIn,
        pageBuilder: (context, state) =>
            _transition(state, const SignInScreen()),
      ),
      GoRoute(
        path: NamedRoutes.signUp,
        name: NamedRoutes.signUp,
        pageBuilder: (context, state) =>
            _transition(state, const SignUpScreen()),
      ),
      GoRoute(
        path: NamedRoutes.emailVerify,
        name: NamedRoutes.emailVerify,
        pageBuilder: (context, state) {
          final data = state.extra as VerificationRouteData;
          return _transition(
            state,
            VerifyEmailScreen(email: data.email, context: data.context),
          );
        },
      ),
      GoRoute(
        path: NamedRoutes.sendEmail,
        name: NamedRoutes.sendEmail,
        pageBuilder: (context, state) =>
            _transition(state, const SendEmailScreen()),
      ),
      GoRoute(
        path: NamedRoutes.changePassword,
        name: NamedRoutes.changePassword,
        pageBuilder: (context, state) {
          final token = state.extra as String;
          return _transition(state, ChangePasswordScreen(resetToken: token));
        },
      ),
      GoRoute(
        path: NamedRoutes.main,
        name: NamedRoutes.main,
        pageBuilder: (context, state) =>
            _transition(state, const MainScreen()),
      ),
    ],
  );
}

CustomTransitionPage<dynamic> _transition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}
