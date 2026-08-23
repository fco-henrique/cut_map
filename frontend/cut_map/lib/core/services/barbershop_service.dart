import 'package:cut_map/core/network/api_client.dart';
import 'package:cut_map/core/network/api_error_handler.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';

class BarbershopService with ChangeNotifier {
  final ApiClient api;

  BarbershopService({required this.api});

  Future<List<BarbershopModel>> fetchAllBarbershops({
    String? sortBy,
    double? lat,
    double? lng,
    double? radiusKm,
    int limit = 10,
  }) async {
    try {
      final response = await api.dio.get(
        "/barbershops",
        queryParameters: {
          if (sortBy != null) 'sortBy': sortBy,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radiusKm != null) 'radiusKm': radiusKm,
          'limit': limit,
        },
      );

      final List<dynamic> jsonList = response.data['barbershops'];
      return jsonList
          .map((json) => BarbershopModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }
}