import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';
// import 'package:cut_map/common/constants/app_colors.dart';
// import 'package:cut_map/common/constants/app_fonts.dart';
// import 'package:cut_map/common/extensions/sizes.dart';

class CustomCompactBarberCard extends StatelessWidget {
  final String barberName;
  final double? rating;
  final int? reviewsCount;
  final String? location;
  final String? distance;
  final VoidCallback onTap;

  const CustomCompactBarberCard({
    super.key,
    required this.barberName,
    this.rating,
    this.reviewsCount,
    this.location,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppColors.darkGray,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildImageHeader(), _buildCardDetails()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        // A imagem usando Ink para permitir o ripple effect
        Ink(
          width: double.infinity,
          height: 110.h, // Altura menor proporcional ao card
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/img_barber.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Badge de Distância (Amarelo) no canto superior direito
        Positioned(
          top: 8.h,
          right: 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              distance ?? '0.3km',
              style: AppFonts.bold12.apply(
                color: AppColors.background, // Texto escuro para dar contraste
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails() {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            barberName,
            style: AppFonts.bold16.apply(color: AppColors.white),
            maxLines: 1, // Evita que nomes grandes quebrem o card
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

          // Avaliação
          Row(
            children: [
              Icon(Icons.star, color: AppColors.yellow, size: 14),
              SizedBox(width: 4.w),
              Text(
                rating?.toStringAsFixed(1) ?? '0.0',
                style: AppFonts.bold14.apply(color: AppColors.yellow),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${reviewsCount ?? 0})',
                style: AppFonts.regular14.apply(color: AppColors.gray),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Localização
          Text(
            location ?? 'Localização',
            style: AppFonts.regular14.apply(color: AppColors.gray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
