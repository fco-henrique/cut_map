abstract class SignUpScreenState {}

class SignUpScreenInitialState extends SignUpScreenState {}

class SignUpScreenSuccessState extends SignUpScreenState {}

class SignUpScreenLoadingState extends SignUpScreenState {}

class SignUpScreenErrorState extends SignUpScreenState {
  final String message;
  SignUpScreenErrorState(this.message);
}