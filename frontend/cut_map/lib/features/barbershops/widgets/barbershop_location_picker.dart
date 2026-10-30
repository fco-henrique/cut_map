import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/core/services/location_service.dart';
import 'package:cut_map/core/services/reverse_geocoding_service.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BarbershopLocationSelection {
  const BarbershopLocationSelection({
    required this.point,
    this.address,
  });

  final LatLng point;
  final AddressSuggestion? address;
}

class BarbershopLocationPicker extends StatefulWidget {
  const BarbershopLocationPicker({
    super.key,
    required this.initialCenter,
    this.initialSelection,
    this.currentLocation,
    this.initialLocationError,
  });

  final LatLng initialCenter;
  final LatLng? initialSelection;
  final LatLng? currentLocation;
  final String? initialLocationError;

  @override
  State<BarbershopLocationPicker> createState() =>
      _BarbershopLocationPickerState();
}

class _BarbershopLocationPickerState extends State<BarbershopLocationPicker> {
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  late LatLng _mapCenter;
  bool _loadingLocation = false;
  bool _loadingAddress = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialSelection;
    _currentLocation = widget.currentLocation;
    _mapCenter = widget.initialCenter;
    _locationError = widget.initialLocationError;
  }

  void _showLocationError(String message) {
    setState(() => _locationError = message);
  }

  Future<void> _confirmLocation(LatLng point) async {
    if (_loadingAddress) return;
    setState(() => _loadingAddress = true);
    AddressSuggestion? address;
    try {
      address = await locator<ReverseGeocodingService>().lookup(point);
    } catch (_) {
      // A coordenada escolhida continua válida sem endereço sugerido.
    }
    if (!mounted) return;
    Navigator.of(context).pop(BarbershopLocationSelection(
      point: point,
      address: address,
    ));
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingLocation || _loadingAddress) return;
    if (_currentLocation != null) {
      await _confirmLocation(_currentLocation!);
      return;
    }
    setState(() => _loadingLocation = true);
    try {
      final location = await locator<LocationService>().getUserLocation();
      if (!mounted) return;
      await _confirmLocation(location);
    } on LocationServiceException catch (error) {
      if (mounted) _showLocationError(error.message);
    } catch (_) {
      if (mounted) _showLocationError('Não foi possível obter sua localização.');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                key: ValueKey(_mapCenter),
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 15,
                  onTap: (_, point) {
                    if (_loadingAddress) return;
                    setState(() {
                      _selectedLocation = point;
                      _locationError = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.seuapp.pacote',
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.yellow,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Voltar',
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.white,
                          ),
                        ),
                        const Flexible(
                          child: Text(
                            'Toque no mapa para marcar a barbearia',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_locationError != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 86,
                left: 16,
                right: 16,
                child: Material(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '$_locationError Você ainda pode marcar um ponto no mapa.',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ),
              ),
            if (_loadingAddress)
              const Center(
                child: Card(
                  color: AppColors.background,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.yellow),
                        SizedBox(height: 12),
                        Text('Buscando endereço...',
                            style: TextStyle(color: AppColors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: _loadingLocation || _loadingAddress
                        ? null : _useCurrentLocation,
                    icon: _loadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_loadingLocation
                        ? 'Obtendo localização...'
                        : 'Usar localização atual'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _selectedLocation == null || _loadingAddress
                        ? null
                        : () => _confirmLocation(_selectedLocation!),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor: AppColors.darkGray,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Confirmar localização'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 132,
              child: const ColoredBox(
                color: AppColors.background,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(color: AppColors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
