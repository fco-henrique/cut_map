abstract class ChangePasswordScreenState {}

class ChangePasswordScreenInitialState extends ChangePasswordScreenState {}

class ChangePasswordScreenSuccessState extends ChangePasswordScreenState {}

class ChangePasswordScreenLoadingState extends ChangePasswordScreenState {}

class ChangePasswordScreenErrorState extends ChangePasswordScreenState {
  final String message;
  final bool isServerDown;

  ChangePasswordScreenErrorState({required this.message, this.isServerDown = false});
}