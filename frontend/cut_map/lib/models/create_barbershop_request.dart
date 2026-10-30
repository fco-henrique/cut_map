import 'package:cut_map/models/opening_hours_model.dart';
import 'package:latlong2/latlong.dart';

class CreateBarbershopRequest {
  const CreateBarbershopRequest({
    required this.name,
    required this.phone,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.location,
    required this.openingHours,
    this.description,
  });

  final String name;
  final String phone;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final LatLng location;
  final String? description;
  final List<OpeningHoursModel> openingHours;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'phone': phone.replaceAll(RegExp(r'\D'), ''),
    if (description?.trim().isNotEmpty == true)
      'description': description!.trim(),
    'address': {
      'rua': street.trim(),
      'numero': number.trim(),
      'bairro': neighborhood.trim(),
      if (city.trim().isNotEmpty) 'cidade': city.trim(),
      if (state.trim().isNotEmpty) 'estado': state.trim().toUpperCase(),
      'latitude': location.latitude,
      'longitude': location.longitude,
    },
    'openingHours': openingHours.map((hour) => hour.toJson()).toList(),
  };
}
