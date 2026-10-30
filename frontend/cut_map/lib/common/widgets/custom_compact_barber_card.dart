import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';

class CustomCompactBarberCard extends StatelessWidget {
  final String barberName;
  final double? rating;
  final int? reviewsCount;
  final String? location;
  final String? distance;
  final bool? isOpen;
  final VoidCallback onTap;

  const CustomCompactBarberCard({
    super.key,
    required this.barberName,
    this.rating,
    this.reviewsCount,
    this.location,
    this.distance,
    this.isOpen,
    required this.onTap,
  });

  // Altura total: imagem (110) + padding vertical (24) + nome (~20) +
  // spacing (4) + rating (~20) + spacing (4) + localização (~20) + folga.
  static const double cardHeight = 214;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.w,
      height: cardHeight.h,
      child: Container(
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
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        Ink(
          width: double.infinity,
          height: 110.h, 
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/img_barber.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        if (isOpen != null)
          Positioned(
            bottom: 12.h,
            left: 12.w,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOpen == true
                    ? AppColors.greenSnack.withValues(alpha: 0.2)
                    : AppColors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOpen == true
                      ? AppColors.greenSnack
                      : AppColors.red,
                  width: 1.5,
                ),
              ),
              child: Text(
                isOpen == true ? 'Aberto' : 'Fechado',
                style: AppFonts.bold12.apply(
                  color: isOpen == true
                      ? AppColors.greenSnack
                      : AppColors.red,
                ),
              ),
            ),
          ),
        if (distance != null)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(distance!,
                  style: AppFonts.bold12.apply(color: AppColors.background)),
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
          Text(
            barberName,
            style: AppFonts.bold16.apply(color: AppColors.white),
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),

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
