import 'package:cut_map/core/services/barbershop_service.dart';
import 'package:cut_map/core/services/location_service.dart';
import 'package:cut_map/features/home/states/section_state.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

typedef BarbershopsState = SectionState<List<BarbershopModel>>;

class HomeScreenController extends ChangeNotifier {
  final BarbershopService _barbershopService;
  final LocationService _locationService;

  HomeScreenController({
    required BarbershopService barbershopService,
    required LocationService locationService,
  })  : _barbershopService = barbershopService,
        _locationService = locationService;

  // Cada seção tem seu próprio ValueNotifier: quem escuta um deles
  // não é notificado quando outra seção muda de estado.
  final ValueNotifier<BarbershopsState> nearbyState =
      ValueNotifier(const SectionInitialState());

  final ValueNotifier<BarbershopsState> topRatedState =
      ValueNotifier(const SectionInitialState());

  // Usada como fallback quando o usuário nega permissão de localização
  // ou o serviço de GPS está desativado.
  static const _fallbackLocation = LatLng(-4.973298, -39.017563);

  LatLng? _userLocation;
  LatLng get userLocation => _userLocation ?? _fallbackLocation;
  bool get isUsingFallbackLocation => _userLocation == null;

  /// Dispara todas as seções em paralelo. Uma seção falhando não
  /// impede as outras de carregarem normalmente.
  Future<void> loadAll() async {
    await Future.wait([
      loadNearby(),
      loadTopRated(),
    ]);
  }

  Future<void> loadNearby() async {
    nearbyState.value = const SectionLoadingState();

    LatLng locationToUse = _fallbackLocation;

    try {
      locationToUse = await _locationService.getUserLocation();
      _userLocation = locationToUse;
    } on LocationServiceException catch (locationError) {
      if (locationError.reason == LocationFailureReason.permissionDeniedForever) {
        // Bloqueio persistente: vale a pena parar aqui e oferecer um
        // atalho pras configurações, em vez de seguir silenciosamente
        // com o fallback (o usuário provavelmente quer corrigir isso).
        nearbyState.value = SectionErrorState(
          message: locationError.message,
          isLocationBlocked: true,
        );
        return;
      }
      // GPS desligado ou negado uma vez: segue com o fallback,
      // sem interromper a seção por um problema recuperável.
    }

    try {
      final barbershops = await _barbershopService.fetchAllBarbershops(
        sortBy: 'distance',
        lat: locationToUse.latitude,
        lng: locationToUse.longitude,
      );

      nearbyState.value = SectionSuccessState(data: barbershops);
    } catch (e) {
      nearbyState.value = SectionErrorState(
        message: _mapError(e),
        isServerDown: _isServerDown(e),
      );
    }
  }

  /// Abre as configurações do app pro usuário liberar a permissão
  /// manualmente, quando ela foi negada permanentemente.
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> loadTopRated() async {
    topRatedState.value = const SectionLoadingState();

    try {
      final barbershops = await _barbershopService.fetchAllBarbershops(sortBy: 'rating');
      topRatedState.value = SectionSuccessState(data: barbershops);
    } catch (e) {
      topRatedState.value = SectionErrorState(
        message: _mapError(e),
        isServerDown: _isServerDown(e),
      );
    }
  }

  String _mapError(Object e) => e.toString();

  bool _isServerDown(Object e) {
    final message = e.toString();
    return message.contains('Não foi possível conectar') ||
        message.contains('Servidor demorou a responder') ||
        message.contains('offline');
  }

  @override
  void dispose() {
    nearbyState.dispose();
    topRatedState.dispose();
    super.dispose();
  }
}