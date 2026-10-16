import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMapPreview extends StatelessWidget {
  final List<BarbershopModel> barbearias;
  final LatLng centro;
  final LatLng? userLocation;
  final VoidCallback onVerNoMapa;

  const CustomMapPreview({
    super.key,
    required this.barbearias,
    required this.centro,
    required this.userLocation,
    required this.onVerNoMapa,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150.h,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey('${centro.latitude},${centro.longitude}'),
              options: MapOptions(
                initialCenter: centro,
                initialZoom: 17,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.seuapp.pacote',
                ),
                MarkerLayer(
                  markers: barbearias
                      .where((b) => b.location != null)
                      .map(
                        (b) => Marker(
                          point: b.location!,
                          width: 36,
                          height: 36,
                          child: const _MarcadorBarbearia(),
                        ),
                      )
                      .toList(),
                ),
                if (userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLocation!,
                        width: 36,
                        height: 36,
                        child: const _UserLocationMarker(),
                      ),
                    ],
                  ),
              ],
            ),

            Positioned(
              left: 16,
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${barbearias.length} barbearias',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userLocation == null
                        ? 'Localização indisponível'
                        : 'próximas a você',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 13.s,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: onVerNoMapa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow, // seu amarelo
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text(
                  'Ver no mapa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarcadorBarbearia extends StatelessWidget {
  const _MarcadorBarbearia();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: const Icon(Icons.content_cut, color: Colors.amber, size: 18),
    );
  }
}
