abstract class SignUpScreenState {}

class SignUpScreenInitialState extends SignUpScreenState {}

class SignUpScreenSuccessState extends SignUpScreenState {}

class SignUpScreenLoadingState extends SignUpScreenState {}

class SignUpScreenErrorState extends SignUpScreenState {
  final String message;
  final bool isServerDown;

  SignUpScreenErrorState({required this.message, this.isServerDown = false});
}