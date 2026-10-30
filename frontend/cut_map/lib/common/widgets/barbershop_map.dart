import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BarbershopMap extends StatelessWidget {
  const BarbershopMap({
    super.key,
    required this.barbearias,
    required this.centro,
    required this.userLocation,
    required this.onBarbershopTap,
    this.initialZoom = 17,
  });

  final List<BarbershopModel> barbearias;
  final LatLng centro;
  final LatLng? userLocation;
  final ValueChanged<BarbershopModel> onBarbershopTap;
  final double initialZoom;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      key: ValueKey('${centro.latitude},${centro.longitude}'),
      options: MapOptions(
        initialCenter: centro,
        initialZoom: initialZoom,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.seuapp.pacote',
        ),
        MarkerLayer(
          markers: barbearias
              .where((barbearia) => barbearia.location != null)
              .map(
                (barbearia) => Marker(
                  point: barbearia.location!,
                  width: 142,
                  height: 68,
                  child: _BarbershopMarker(
                    name: barbearia.name,
                    onTap: () => onBarbershopTap(barbearia),
                  ),
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

class _BarbershopMarker extends StatelessWidget {
  const _BarbershopMarker({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver barbearia $name',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.yellow),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.yellow, width: 2),
              ),
              child: const Icon(Icons.content_cut,
                  color: AppColors.yellow, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
