import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/verify_email_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/foundation.dart';

class VerifyEmailScreenController extends ChangeNotifier {
  final AuthService _authService;

  VerifyEmailScreenController({required AuthService authService})
    : _authService = authService;

  VerifyEmailScreenState _state = VerifyEmailScreenInitialState();
  VerifyEmailScreenState get state => _state;

  void _changeState(VerifyEmailScreenState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> verifyEmail(String email, String code) async {
    _changeState(VerifyEmailScreenLoadingState());

    try {
      final tokens = await _authService.verifyEmail(email: email, code: code);

      final authManager = locator.get<AuthManager>();
      await authManager.login(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );
      
      _changeState(VerifyEmailScreenSuccessState());
    } catch (e) {
      final errorMessage = e.toString();

      final isServerDown =
          errorMessage.contains('Não foi possível conectar') ||
          errorMessage.contains('Servidor demorou a responder') ||
          errorMessage.contains('offline');

      _changeState(
        VerifyEmailScreenErrorState(
          message: errorMessage,
          isServerDown: isServerDown,
        ),
      );
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    _changeState(VerifyEmailScreenLoadingState());

    try {
      await _authService.resendVerificationEmail(email: email);
      _changeState(VerifyEmailScreenResendSuccessState());
    } catch (e) {
      final errorMessage = e.toString();

      final isServerDown =
          errorMessage.contains('Não foi possível conectar') ||
          errorMessage.contains('Servidor demorou a responder') ||
          errorMessage.contains('offline');

      _changeState(
        VerifyEmailScreenErrorState(
          message: errorMessage,
          isServerDown: isServerDown,
        ),
      );
    }
  }
}
