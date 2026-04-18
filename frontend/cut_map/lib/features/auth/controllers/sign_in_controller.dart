import 'dart:developer';

import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/sign_in_state.dart';
import 'package:flutter/foundation.dart';

class SignInScreenController extends ChangeNotifier {
  final AuthService _authService;

  SignInScreenController({required AuthService authService})
    : _authService = authService;

  SignInScreenState _state = SignInScreenInitialState();
  SignInScreenState get state => _state;

  void _changeState(SignInScreenState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _changeState(SignInScreenLoadingState());

    try {
      await _authService.signIn(email: email, password: password);
      log('Usuário autenticado com sucesso via API com Dio');

      _changeState(SignInScreenSuccessState());
    } catch (e) {
      final errorMessage = e.toString();

      final isServerDown = errorMessage.contains('Não foi possível conectar');
      log('Erro inesperado no controller: $e');
      _changeState(
        SignInScreenErrorState(
          message: errorMessage,
          isServerDown: isServerDown,
        ),
      );
    }
  }
}
