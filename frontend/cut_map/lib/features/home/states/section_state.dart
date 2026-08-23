sealed class SectionState<T> {
  const SectionState();
}

class SectionInitialState<T> extends SectionState<T> {
  const SectionInitialState();
}

class SectionLoadingState<T> extends SectionState<T> {
  const SectionLoadingState();
}

class SectionSuccessState<T> extends SectionState<T> {
  final T data;
  const SectionSuccessState({required this.data});
}

class SectionErrorState<T> extends SectionState<T> {
  final String message;
  final bool isServerDown;
  final bool isLocationBlocked;
  const SectionErrorState({
    required this.message,
    this.isServerDown = false,
    this.isLocationBlocked = false,
  });
}