abstract class VerifyEmailScreenState {}

class VerifyEmailScreenInitialState extends VerifyEmailScreenState {}

class VerifyEmailScreenSuccessState extends VerifyEmailScreenState {}

class VerifyEmailScreenResendSuccessState extends VerifyEmailScreenState {}

class VerifyEmailScreenResetSuccessState extends VerifyEmailScreenState {
  final String resetToken;
  VerifyEmailScreenResetSuccessState(this.resetToken);
}

class VerifyEmailScreenLoadingState extends VerifyEmailScreenState {}

class VerifyEmailScreenErrorState extends VerifyEmailScreenState {
  final String message;
  final bool isServerDown;

  VerifyEmailScreenErrorState({
    required this.message,
    this.isServerDown = false,
  });
}
