import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/widgets/barbershop_map.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CustomMapPreview extends StatelessWidget {
  final List<BarbershopModel> barbearias;
  final LatLng centro;
  final LatLng? userLocation;
  final VoidCallback onVerNoMapa;
  final ValueChanged<BarbershopModel> onBarbershopTap;

  const CustomMapPreview({
    super.key,
    required this.barbearias,
    required this.centro,
    required this.userLocation,
    required this.onVerNoMapa,
    required this.onBarbershopTap,
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
            BarbershopMap(
              barbearias: barbearias,
              centro: centro,
              userLocation: userLocation,
              onBarbershopTap: onBarbershopTap,
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
                  backgroundColor: AppColors.yellow,
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
