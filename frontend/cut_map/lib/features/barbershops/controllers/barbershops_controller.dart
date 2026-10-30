import 'package:cut_map/core/services/barbershop_service.dart';
import 'package:cut_map/features/barbershops/states/barbershops_state.dart';
import 'package:flutter/foundation.dart';

class BarbershopsController extends ChangeNotifier {
  BarbershopsController({required BarbershopService barbershopService})
      : _barbershopService = barbershopService;

  final BarbershopService _barbershopService;
  BarbershopsState _state = const BarbershopsInitial();
  BarbershopsState get state => _state;
  bool _disposed = false;

  Future<void> load() async {
    _state = const BarbershopsLoading();
    notifyListeners();
    try {
      final items = await _barbershopService.fetchMyBarbershops();
      if (_disposed) return;
      _state = BarbershopsLoaded(items);
    } catch (error) {
      if (_disposed) return;
      _state = BarbershopsFailure(error.toString());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
