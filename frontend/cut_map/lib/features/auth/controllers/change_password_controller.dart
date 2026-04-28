import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/change_password_state.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreenController extends ChangeNotifier {
  final AuthService _authService;

  ChangePasswordScreenController({required AuthService authService})
    : _authService = authService;

  ChangePasswordScreenState _state = ChangePasswordScreenInitialState();
  ChangePasswordScreenState get state => _state;

  void _changeState(ChangePasswordScreenState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    _changeState(ChangePasswordScreenLoadingState());

    try {
      await _authService.resetPassword(resetToken: resetToken, newPassword: newPassword);
      _changeState(ChangePasswordScreenSuccessState());
    } catch (e) {
      final errorMessage = e.toString();

      final isServerDown =
          errorMessage.contains('Não foi possível conectar') ||
          errorMessage.contains('Servidor demorou a responder') ||
          errorMessage.contains('offline');

      _changeState(
        ChangePasswordScreenErrorState(
          message: errorMessage,
          isServerDown: isServerDown,
        ),
      );
    }
  }
  
}