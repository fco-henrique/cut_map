import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/widgets/custom_barber_card.dart';
import 'package:cut_map/common/widgets/custom_compact_barber_card.dart';
import 'package:cut_map/common/widgets/custom_notification_button.dart';
import 'package:cut_map/common/widgets/custom_profile_avatar.dart';
import 'package:cut_map/common/widgets/custom_text_form_field.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 50.h),
              //CABEÇALHO COM NOTIFICAÇÕES E AVATAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Olá,",
                        style: AppFonts.regular16.apply(color: AppColors.white),
                      ),
                      Text(
                        "Usuário",
                        style: AppFonts.bold24.apply(color: AppColors.white),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      CustomNotificationButton(
                        onTap: () async {
                          final authManager = locator.get<AuthManager>();
                          await authManager.logout();
                        },
                        notificationCount: 2,
                      ),
                      CustomProfileAvatar(
                        imageUrl: "assets/images/img_perfil.jpg",
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // CAMPO DE LOCALIZAÇÃO
              Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.yellow,
                    size: 20.s,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Bairro, ",
                          style: AppFonts.light18.apply(
                            color: AppColors.lightGray,
                          ),
                        ),
                        TextSpan(
                          text: "Cidade",
                          style: AppFonts.light18.apply(
                            color: AppColors.lightGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Alterar",
                    style: AppFonts.medium14.apply(color: AppColors.yellow),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // CAMPO DE PESQUISA
              CustomTextFormField(
                hintText: "Pesquisar barbearias",
                prefixIcon: Icons.search,
                padding: EdgeInsets.symmetric(horizontal: 0),
              ),
              SizedBox(height: 10.h),

              // LUGAR RESERVADO PARA O MAPA
              Container(
                height: 150.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.gray.withValues(alpha: 0.2),
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Próximas a você",
                    style: AppFonts.bold18.apply(color: AppColors.white),
                  ),
                  Row(
                    children: [
                      Text(
                        "Ver todas ",
                        style: AppFonts.medium16.apply(color: AppColors.yellow),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              // CARDS DE BARBEARIAS COMPACTAS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,
                  children: [
                    CustomCompactBarberCard(
                      barberName: "Lelo Barber",
                      onTap: () {},
                      distance: "1.7km",
                      location: "Centro",
                      rating: 4.2,
                      reviewsCount: 67,
                    ),
                    CustomCompactBarberCard(
                      barberName: "Kings Barber",
                      onTap: () {},
                    ),
                    CustomCompactBarberCard(
                      barberName: "Biro Barber",
                      onTap: () {},
                    ),
                    CustomCompactBarberCard(
                      barberName: "Nereu Barber",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Mais bem avaliadas",
                    style: AppFonts.bold18.apply(color: AppColors.white),
                  ),
                  Row(
                    children: [
                      Text(
                        "Ver todas ",
                        style: AppFonts.medium16.apply(color: AppColors.yellow),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.yellow,
                      ),
                    ],
                  ),
                ],
              ),
              // CARDS DE BARBEARIAS
              SizedBox(height: 10.h),
              CustomBarberCard(barberName: "Kings Barber"),
              SizedBox(height: 10.h),
              CustomBarberCard(barberName: "Kings Barber"),
              SizedBox(height: 10.h),
              CustomBarberCard(barberName: "Kings Barber"),
              SizedBox(height: 10.h),

              // INFORMATIVO DE PRÓXIMO AGENDAMENTO
              SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Próximo agendamento',
                            style: AppFonts.bold16.apply(
                              color: AppColors.background,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'NewBarber • Hoje 15:00',
                            style: AppFonts.regular14.apply(
                              color: AppColors.background.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 12.w),
                    Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          child: Text(
                            'Ver',
                            style: AppFonts.bold14.apply(
                              color: AppColors.yellow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
