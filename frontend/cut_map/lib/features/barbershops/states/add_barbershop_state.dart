import 'package:cut_map/models/opening_hours_model.dart';
import 'package:latlong2/latlong.dart';

class AddBarbershopState {
  const AddBarbershopState({
    this.step = 0,
    this.selectedLocation,
    this.openingHours = const [],
    this.isSubmitting = false,
    this.error,
  });

  final int step;
  final LatLng? selectedLocation;
  final List<OpeningHoursModel> openingHours;
  final bool isSubmitting;
  final String? error;

  bool get hasValidHours => openingHours.isNotEmpty &&
      openingHours.every((hour) => hour.isValid);

  AddBarbershopState copyWith({
    int? step,
    LatLng? selectedLocation,
    List<OpeningHoursModel>? openingHours,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) => AddBarbershopState(
    step: step ?? this.step,
    selectedLocation: selectedLocation ?? this.selectedLocation,
    openingHours: openingHours ?? this.openingHours,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : error ?? this.error,
  );
}
