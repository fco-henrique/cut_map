abstract class SignInScreenState {}

class SignInScreenInitialState extends SignInScreenState {}

class SignInScreenSuccessState extends SignInScreenState {}

class SignInScreenLoadingState extends SignInScreenState {}

class SignInScreenErrorState extends SignInScreenState {
  final String message;
  final bool isServerDown;

  SignInScreenErrorState({required this.message, this.isServerDown = false});
}
