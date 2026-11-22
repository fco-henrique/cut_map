import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/auth/services/auth_service.dart';
import 'package:cut_map/features/auth/states/update_password_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/foundation.dart';

class UpdatePasswordController extends ChangeNotifier {
  final AuthService _authService;
  final AuthManager? _authManager;

  UpdatePasswordController({
    required AuthService authService,
    AuthManager? authManager,
  }) : _authService = authService,
       _authManager = authManager;

  UpdatePasswordState _state = UpdatePasswordInitialState();
  UpdatePasswordState get state => _state;

  AuthManager get _resolvedAuthManager =>
      _authManager ?? locator.get<AuthManager>();

  void _changeState(UpdatePasswordState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _changeState(UpdatePasswordLoadingState());

    try {
      String userId = _resolvedAuthManager.user?.id ?? '';
      if (userId.isEmpty) {
        final currentUser = await _authService.getCurrentUser();
        userId = currentUser.id;
      }

      if (userId.isEmpty) {
        throw 'Não foi possível identificar o usuário autenticado.';
      }

      await _authService.updatePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Troca de senha autenticada preserva as sessões existentes.
      _changeState(UpdatePasswordSuccessState());
    } catch (e) {
      final errorMessage = e.toString();

      final isServerDown =
          errorMessage.contains('Não foi possível conectar') ||
          errorMessage.contains('Servidor demorou a responder') ||
          errorMessage.contains('offline');

      _changeState(
        UpdatePasswordErrorState(
          message: errorMessage,
          isServerDown: isServerDown,
        ),
      );
    }
  }
}
