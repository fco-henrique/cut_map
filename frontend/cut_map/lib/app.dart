import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/features/auth/screens/change_password_screen.dart';
import 'package:cut_map/features/auth/screens/send_email_screen.dart';
import 'package:cut_map/features/auth/screens/sign_in_screen.dart';
import 'package:cut_map/features/auth/screens/sign_up_screen.dart';
import 'package:cut_map/features/auth/screens/verify_email_screen.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
// import 'package:cut_map/features/home/screens/home_screen.dart';
import 'package:cut_map/features/splash/splash_screen.dart';
import 'package:cut_map/features/welcome/welcome_screen.dart';
import 'package:cut_map/locator.dart';
import 'package:cut_map/main_screen.dart';
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

enum VerificationContext { signUp, forgotPassword }

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
      NamedRoutes.sendEmail,
      NamedRoutes.changePassword,
      NamedRoutes.welcome,
    ];

    final isGoingToPublicRoute = publicRoutes.contains(state.matchedLocation);

    if (!isLoggedIn && !isGoingToPublicRoute) {
      return NamedRoutes.signIn;
    }

    final isGoingToLoginOrSplash =
        state.matchedLocation == NamedRoutes.signIn ||
        state.matchedLocation == NamedRoutes.splash;

    if (isLoggedIn && isGoingToLoginOrSplash) {
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
      pageBuilder: (context, state) {
        return transition(state, const WelcomeScreen());
      },
    ),
    GoRoute(
      path: NamedRoutes.signIn,
      name: NamedRoutes.signIn,
      pageBuilder: (context, state) => transition(state, const SignInScreen()),
    ),
    GoRoute(
      path: NamedRoutes.signUp,
      name: NamedRoutes.signUp,
      pageBuilder: (context, state) => transition(state, const SignUpScreen()),
    ),
    GoRoute(
      path: NamedRoutes.emailVerify,
      name: NamedRoutes.emailVerify,
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return transition(
          state,
          VerifyEmailScreen(
            email: data['email'] as String,
            context: data['context'] as VerificationContext,
          ),
        );
      },
    ),
    GoRoute(
      path: NamedRoutes.sendEmail,
      name: NamedRoutes.sendEmail,
      pageBuilder: (context, state) =>
          transition(state, const SendEmailScreen()),
    ),
    GoRoute(
      path: NamedRoutes.changePassword,
      name: NamedRoutes.changePassword,
      pageBuilder: (context, state) {
        final token = state.extra as String;
        return transition(state, ChangePasswordScreen(resetToken: token));
      },
    ),
    GoRoute(
      path: NamedRoutes.main,
      name: NamedRoutes.main,
      pageBuilder: (context, state) => transition(state, const MainScreen()),
    ),
    // GoRoute(
    //   path: NamedRoutes.home,
    //   name: NamedRoutes.home,
    //   pageBuilder: (context, state) => transition(state, const HomeScreen()),
    // ),
  ],
);

CustomTransitionPage<dynamic> transition(GoRouterState state, Widget child) {
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
