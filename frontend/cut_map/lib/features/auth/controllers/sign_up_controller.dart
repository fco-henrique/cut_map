import 'dart:developer';

import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/sign_up_state.dart';
import 'package:flutter/foundation.dart';

class SignUpScreenController extends ChangeNotifier {
  final AuthService _authService;

  SignUpScreenController({required AuthService authService}) : _authService = authService;

  SignUpScreenState _state = SignUpScreenInitialState();
  SignUpScreenState get state => _state;

  void _changeState(SignUpScreenState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    log("Os dados chegaram no controller name: $name email: $email password: $password");
    _changeState(SignUpScreenLoadingState());
    try {
      await _authService.signUp(
        name: name,
        email: email,
        password: password.trim(),
      );

      // await _authService.signIn(
      //   email: email,
      //   password: password.trim(),
      // );
      log("Usuário criado com sucesso via API com Dio");
      _changeState(SignUpScreenSuccessState());
    } catch (e) {
      log("Erro ao criar usuário: $e");
      _changeState(
        SignUpScreenErrorState(e.toString().replaceFirst("Exception: ", "")),
      );
    }
  }
}
