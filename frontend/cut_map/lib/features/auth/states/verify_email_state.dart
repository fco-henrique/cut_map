abstract class VerifyEmailScreenState {}

class VerifyEmailScreenInitialState extends VerifyEmailScreenState {}

class VerifyEmailScreenSuccessState extends VerifyEmailScreenState {}

class VerifyEmailScreenResendSuccessState extends VerifyEmailScreenState {}

class VerifyEmailScreenLoadingState extends VerifyEmailScreenState {}

class VerifyEmailScreenErrorState extends VerifyEmailScreenState {
  final String message;
  final bool isServerDown;

  VerifyEmailScreenErrorState({
    required this.message,
    this.isServerDown = false,
  });
}
