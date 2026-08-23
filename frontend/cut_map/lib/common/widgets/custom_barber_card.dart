import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';

class CustomBarberCard extends StatefulWidget {
  final bool? isFavorite;
  final bool? isOpen;
  final String barberName;
  final double? rating;
  final int? reviewsCount;
  final String? address;
  final String? distance;
  final List<String>? services;
  final String? workingHours;
  final String? startingPrice;

  const CustomBarberCard({
    super.key,
    this.isFavorite = false,
    this.isOpen = true,
    required this.barberName,
    this.rating,
    this.reviewsCount,
    this.address,
    this.distance,
    this.services,
    this.workingHours,
    this.startingPrice,
  });

  @override
  State<CustomBarberCard> createState() => _CustomBarberCardState();
}

class _CustomBarberCardState extends State<CustomBarberCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppColors.darkGray,
          child: InkWell(
            onTap: () {
              // Ação de navegação para detalhes
            },
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
        //imagem
        Ink(
          width: double.infinity,
          height: 180.h,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/img_barber.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Ink(
          width: double.infinity,
          height: 180.h,
          color: AppColors.background.withValues(alpha: 0.2),
        ),
        // icone de coração
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: AppColors.gray.withValues(alpha: 0.2),
            shape: CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.yellow,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        //aviso de aberto
        Positioned(
          bottom: 12.h,
          left: 12.w,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isOpen == true
                  ? AppColors.greenSnack.withValues(alpha: 0.2)
                  : AppColors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isOpen == true
                    ? AppColors.greenSnack
                    : AppColors.red,
                width: 1.5,
              ),
            ),
            child: Text(
              widget.isOpen == true ? 'Aberto agora' : 'Fechado agora',
              style: AppFonts.bold12.apply(
                color: widget.isOpen == true
                    ? AppColors.greenSnack
                    : AppColors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.barberName,
                  style: AppFonts.bold18.apply(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.yellow, size: 18),
                  SizedBox(width: 4),
                  Text(
                    widget.rating?.toStringAsFixed(1) ?? '0.0',
                    style: AppFonts.bold16.apply(color: AppColors.yellow),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${widget.reviewsCount ?? 0})',
                    style: AppFonts.regular16.apply(color: AppColors.gray),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.gray, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.address ?? 'Localização'} • ${widget.distance ?? '0.3km'}',
                  style: AppFonts.regular14.apply(color: AppColors.gray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.services != null)
                  ...widget.services!.map(
                    (service) => _buildServiceTag(service),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, color: AppColors.gray, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.workingHours ?? '08:00 - 20:00',
                        style: AppFonts.regular14.apply(color: AppColors.gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.startingPrice ?? 'A partir de R\$15',
                  style: AppFonts.bold14.apply(color: AppColors.yellow),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blackDarkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppFonts.regular14.apply(color: AppColors.lightGray),
      ),
    );
  }
}