abstract class UpdatePasswordState {}

class UpdatePasswordInitialState extends UpdatePasswordState {}

class UpdatePasswordLoadingState extends UpdatePasswordState {}

class UpdatePasswordSuccessState extends UpdatePasswordState {}

class UpdatePasswordErrorState extends UpdatePasswordState {
  final String message;
  final bool isServerDown;

  UpdatePasswordErrorState({required this.message, this.isServerDown = false});
}
