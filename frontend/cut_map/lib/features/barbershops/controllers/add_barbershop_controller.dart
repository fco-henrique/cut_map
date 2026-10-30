import 'package:cut_map/core/services/barbershop_service.dart';
import 'package:cut_map/features/barbershops/states/add_barbershop_state.dart';
import 'package:cut_map/models/create_barbershop_request.dart';
import 'package:cut_map/models/opening_hours_model.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class AddBarbershopController extends ChangeNotifier {
  AddBarbershopController({required BarbershopService barbershopService})
      : _barbershopService = barbershopService;

  final BarbershopService _barbershopService;
  AddBarbershopState _state = const AddBarbershopState();
  AddBarbershopState get state => _state;
  bool _disposed = false;

  void _emit(AddBarbershopState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  void setStep(int step) => _emit(_state.copyWith(step: step, clearError: true));

  void selectLocation(LatLng location) =>
      _emit(_state.copyWith(selectedLocation: location, clearError: true));

  void toggleDay(int day) {
    final hours = [..._state.openingHours];
    if (hours.any((hour) => hour.dayOfWeek == day)) {
      hours.removeWhere((hour) => hour.dayOfWeek == day);
    } else {
      hours.add(OpeningHoursModel(
        dayOfWeek: day,
        opensAt: '09:00',
        closesAt: '18:00',
      ));
    }
    hours.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    _emit(_state.copyWith(openingHours: hours, clearError: true));
  }

  void updateHours(OpeningHoursModel updated) {
    final hours = [
      for (final hour in _state.openingHours)
        if (hour.dayOfWeek == updated.dayOfWeek) updated else hour,
    ];
    _emit(_state.copyWith(openingHours: hours, clearError: true));
  }

  Future<bool> submit(CreateBarbershopRequest request) async {
    if (_state.isSubmitting) return false;
    if (!_state.hasValidHours) {
      _emit(_state.copyWith(error: 'Confira os horários de funcionamento.'));
      return false;
    }
    _emit(_state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _barbershopService.createBarbershop(request);
      if (_disposed) return false;
      _emit(_state.copyWith(isSubmitting: false, clearError: true));
      return true;
    } catch (error) {
      if (_disposed) return false;
      _emit(_state.copyWith(isSubmitting: false, error: error.toString()));
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
