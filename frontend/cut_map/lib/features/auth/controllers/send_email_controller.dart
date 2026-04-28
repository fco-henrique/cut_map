import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/send_email_state.dart';
import 'package:flutter/material.dart';

class SendEmailScreenController extends ChangeNotifier {
  final AuthService _authService;

  SendEmailScreenController({required AuthService authService})
    : _authService = authService;

  SendEmailScreenState _state = SendEmailScreenInitialState();
  SendEmailScreenState get state => _state;

  void _changeState(SendEmailScreenState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    _changeState(SendEmailScreenLoadingState());

    try {
      await _authService.forgotPassword(email: email);
      _changeState(SendEmailScreenSuccessState());
    } catch (e) {
      final errorMessage = e.toString();

      final isServerDown =
          errorMessage.contains('Não foi possível conectar') ||
          errorMessage.contains('Servidor demorou a responder') ||
          errorMessage.contains('offline');

      _changeState(
        SendEmailScreenErrorState(
          message: errorMessage,
          isServerDown: isServerDown,
        ),
      );
    }
  }
}
