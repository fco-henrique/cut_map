abstract class SendEmailScreenState {}

class SendEmailScreenInitialState extends SendEmailScreenState {}

class SendEmailScreenSuccessState extends SendEmailScreenState {}

class SendEmailScreenLoadingState extends SendEmailScreenState {}

class SendEmailScreenErrorState extends SendEmailScreenState {
  final String message;
  final bool isServerDown;

  SendEmailScreenErrorState({required this.message, this.isServerDown = false});
}