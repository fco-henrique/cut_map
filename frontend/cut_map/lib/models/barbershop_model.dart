import 'package:cut_map/common/utils/json_parsers.dart';
import 'package:cut_map/models/address_model.dart';
import 'package:latlong2/latlong.dart';

class BarbershopModel {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final AddressModel address;
  final String imageUrl;
  final double? distanceInKm;

  BarbershopModel({
    required this.id,
    required this.name,
    required this.address,
    this.rating = 4.5,
    this.reviewsCount = 100,
    this.imageUrl = "assets/images/img_barber.jpg",
    this.distanceInKm,
  });

  factory BarbershopModel.fromJson(Map<String, dynamic> json) {
  return BarbershopModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    address: AddressModel.fromJson(json['address'] ?? {}),
    rating: JsonParsers.toDoubleOrNull(json['averageRating']) ?? 4.5,
    reviewsCount: json['totalReviews'] ?? 100,
    imageUrl: json['imageUrl'] ?? "assets/images/img_barber.jpg",
    distanceInKm: JsonParsers.toDoubleOrNull(json['distanceInKm']),
  );
}

  LatLng? get location {
    if (address.latitude == null || address.longitude == null) return null;
    return LatLng(address.latitude!, address.longitude!);
  }
}