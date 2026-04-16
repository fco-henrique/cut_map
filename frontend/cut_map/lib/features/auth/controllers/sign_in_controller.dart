import 'dart:developer';

import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/sign_in_state.dart';
import 'package:flutter/foundation.dart';

class SignInScreenController extends ChangeNotifier {
  final AuthService _authService;

  SignInScreenController({required AuthService authService})
    : _authService = authService;

  SignInState _state = SignInInitialState();
  SignInState get state => _state;

  void _changeState(SignInState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _changeState(SignInLoadingState());

    try {
      await _authService.signIn(email: email, password: password);
      log('Usuário autenticado com sucesso via API com Dio');

      _changeState(SignInSuccessState());
    } catch (e) {
      log('Erro inesperado no controller: $e');
      _changeState(SignInErrorState());
    }
  }
}
