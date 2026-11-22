import 'package:cut_map/features/onboarding/services/onboarding_storage.dart';
import 'package:flutter/foundation.dart';

class OnboardingManager extends ChangeNotifier {
  final OnboardingStorage storage;

  bool _isInitialized = false;
  bool _hasSeenOnboarding = false;
  Future<void>? _initFuture;

  bool get isInitialized => _isInitialized;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  OnboardingManager({required this.storage, bool autoInitialize = true}) {
    if (autoInitialize) {
      initialize();
    }
  }

  Future<void> initialize() {
    return _initFuture ??= _loadFlag();
  }

  Future<void> _loadFlag() async {
    _hasSeenOnboarding = await storage.hasSeenOnboarding();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (!_hasSeenOnboarding) {
      await storage.markOnboardingAsSeen();
      _hasSeenOnboarding = true;
    }
    _isInitialized = true;
    notifyListeners();
  }
}
