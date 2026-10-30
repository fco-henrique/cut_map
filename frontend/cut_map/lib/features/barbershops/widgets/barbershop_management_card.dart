import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BarbershopManagementCard extends StatelessWidget {
  const BarbershopManagementCard({
    super.key,
    required this.isOwner,
    required this.barbershop,
    this.status = BarbershopStatus.active,
  });

  final bool isOwner;
  final BarbershopModel barbershop;
  final BarbershopStatus status;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.blackDarkGray,
          border: Border.all(color: AppColors.darkGray),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _buildImageHeader(),
            _buildDetails(),
            if (isOwner) _buildManageButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    final isOpen = barbershop.isOpenAt(DateTime.now());
    String textStatus = isOpen != null
        ? (isOpen ? 'Aberta' : 'Fechada')
        : status == BarbershopStatus.active
        ? 'Ativa'
        : status == BarbershopStatus.inactive
        ? 'Inativa'
        : 'Pendente';

    Color backgroundColor = isOpen != null
        ? (isOpen ? AppColors.greenSnack : AppColors.red)
            .withValues(alpha: 0.2)
        : status == BarbershopStatus.active
        ? AppColors.greenSnack.withValues(alpha: 0.2)
        : status == BarbershopStatus.inactive
        ? AppColors.red.withValues(alpha: 0.2)
        : AppColors.yellow.withValues(alpha: 0.2);

    Color borderTextColor = isOpen != null
        ? (isOpen ? AppColors.greenSnack : AppColors.red)
        : status == BarbershopStatus.active
        ? AppColors.greenSnack
        : status == BarbershopStatus.inactive
        ? AppColors.red
        : AppColors.yellow;

    return SizedBox(
      height: 122,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/img_barber.jpg', fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
                stops: [0, 0.38, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                border: Border.all(color: AppColors.yellow),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOwner ? Symbols.crown : Icons.work_outline,
                    size: 12,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOwner ? 'Proprietário' : 'Funcionário',
                    style: AppFonts.bold10.apply(color: AppColors.yellow),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 11,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderTextColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                textStatus,
                style: AppFonts.bold10.apply(color: borderTextColor),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barbershop.name,
                  style: AppFonts.bold16.apply(color: AppColors.white),
                ),
                if (barbershop.reviewsCount > 0) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.star, color: AppColors.yellow, size: 13),
                    const SizedBox(width: 3),
                    Text(barbershop.rating.toStringAsFixed(1),
                        style: AppFonts.semiBold12.apply(color: AppColors.yellow)),
                    const SizedBox(width: 4),
                    Text('(${barbershop.reviewsCount})',
                        style: AppFonts.regular12.apply(color: AppColors.lightGray)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
      child: Column(
        children: [
          if (barbershop.address.formatted.isNotEmpty) _DetailRow(
            icon: Icons.location_on_outlined,
            text: barbershop.address.formatted,
          ),
          if (barbershop.phone?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.phone_outlined, text: barbershop.phone!),
          ],
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.access_time,
              text: 'Hoje: ${barbershop.hoursLabelAt(DateTime.now())}'),
        ],
      ),
    );
  }

  Widget _buildManageButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.darkGray)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gerenciamento de barbearias em breve.'),
                ),
              );
            },
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gerenciar',
                    style: AppFonts.extraBold16.apply(color: AppColors.yellow),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 26,
                    color: AppColors.yellow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.yellow),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.regular14.apply(color: AppColors.gray),
          ),
        ),
      ],
    );
  }
}
