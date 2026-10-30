import 'package:cut_map/common/utils/json_parsers.dart';
import 'package:cut_map/models/address_model.dart';
import 'package:cut_map/models/opening_hours_model.dart';
import 'package:latlong2/latlong.dart';

enum BarbershopStatus {
  active,
  inactive,
  pending,
}

class BarbershopModel {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final AddressModel address;
  final String imageUrl;
  final double? distanceInKm;
  final String? phone;
  final String? description;
  final String? memberRole;
  final List<OpeningHoursModel> openingHours;

  BarbershopModel({
    required this.id,
    required this.name,
    required this.address,
    this.rating = 0,
    this.reviewsCount = 0,
    this.imageUrl = "assets/images/img_barber.jpg",
    this.distanceInKm,
    this.phone,
    this.description,
    this.memberRole,
    this.openingHours = const [],
  });

  factory BarbershopModel.fromJson(Map<String, dynamic> json) {
    final members = json['members'];
    final hours = json['openingHours'];
    return BarbershopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: AddressModel.fromJson(json['address'] ?? {}),
      rating: JsonParsers.toDoubleOrNull(json['averageRating']) ?? 0,
      reviewsCount: json['totalReviews'] ?? 0,
      imageUrl: json['imageUrl'] ?? 'assets/images/img_barber.jpg',
      distanceInKm: JsonParsers.toDoubleOrNull(json['distanceInKm']),
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      memberRole: members is List && members.isNotEmpty
          ? (members.first as Map<String, dynamic>)['role'] as String?
          : null,
      openingHours: hours is List
          ? hours.map((item) => OpeningHoursModel.fromJson(
              item as Map<String, dynamic>,
            )).toList()
          : const [],
    );
  }

  LatLng? get location {
    if (address.latitude == null || address.longitude == null) return null;
    return LatLng(address.latitude!, address.longitude!);
  }

  OpeningHoursModel? hoursFor(DateTime date) {
    for (final hours in openingHours) {
      if (hours.dayOfWeek == date.weekday) return hours;
    }
    return null;
  }

  bool? isOpenAt(DateTime date) {
    if (openingHours.isEmpty) return null;
    final hours = hoursFor(date);
    if (hours == null) return false;
    if (!hours.isValid) return null;

    final now = date.hour * 60 + date.minute;
    int minutes(String time) {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    if (now < minutes(hours.opensAt) || now >= minutes(hours.closesAt)) {
      return false;
    }
    if (hours.hasBreak &&
        now >= minutes(hours.breakStartsAt!) &&
        now < minutes(hours.breakEndsAt!)) {
      return false;
    }
    return true;
  }

  String hoursLabelAt(DateTime date) {
    if (openingHours.isEmpty) return 'Horários não informados';
    final hours = hoursFor(date);
    if (hours == null) return 'Fechada hoje';
    if (!hours.isValid) return 'Horários indisponíveis';
    if (hours.hasBreak) {
      return '${hours.opensAt}–${hours.breakStartsAt} · '
          '${hours.breakEndsAt}–${hours.closesAt}';
    }
    return '${hours.opensAt}–${hours.closesAt}';
  }

  double? distanceFrom(LatLng? origin) {
    final destination = location;
    if (origin == null || destination == null) return null;
    return Distance().as(LengthUnit.Kilometer, origin, destination);
  }
}
