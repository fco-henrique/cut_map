import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationServiceException implements Exception {
  final LocationFailureReason reason;
  final String message;

  LocationServiceException(this.reason, this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Retorna a localização atual do usuário, ou lança
  /// [LocationServiceException] descrevendo o motivo da falha.
  Future<LatLng> getUserLocation() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw LocationServiceException(
        LocationFailureReason.serviceDisabled,
        'Ative o serviço de localização do dispositivo para ver barbearias próximas.',
      );
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw LocationServiceException(
          LocationFailureReason.permissionDenied,
          'Permissão de localização negada.',
        );
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw LocationServiceException(
        LocationFailureReason.permissionDeniedForever,
        'Permissão de localização bloqueada. Ative nas configurações do app.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw LocationServiceException(
        LocationFailureReason.unknown,
        'Não foi possível obter sua localização.',
      );
    }
  }

  Future<LatLng?> getUserLocationOrNull() async {
    try {
      return await getUserLocation();
    } on LocationServiceException {
      return null;
    }
  }
}