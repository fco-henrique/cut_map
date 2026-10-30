import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/widgets/barbershop_map.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class FullMapScreen extends StatelessWidget {
  const FullMapScreen({
    super.key,
    required this.barbearias,
    required this.centro,
    required this.userLocation,
    required this.onBarbershopTap,
  });

  final List<BarbershopModel> barbearias;
  final LatLng centro;
  final LatLng? userLocation;
  final ValueChanged<BarbershopModel> onBarbershopTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: BarbershopMap(
                barbearias: barbearias,
                centro: centro,
                userLocation: userLocation,
                onBarbershopTap: onBarbershopTap,
                initialZoom: 16,
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
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.white,
                              semanticLabel: 'Voltar',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Material(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            child: Text(
                              '${barbearias.length} barbearias no mapa',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Positioned(
            //   left: 12,
            //   bottom: MediaQuery.paddingOf(context).bottom + 12,
            //   child: const DecoratedBox(
            //     decoration: BoxDecoration(color: AppColors.background),
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            //       child: Text(
            //         '© OpenStreetMap contributors',
            //         style: TextStyle(color: AppColors.white, fontSize: 10),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
