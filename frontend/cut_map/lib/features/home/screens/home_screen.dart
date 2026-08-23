import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/widgets/custom_barber_card.dart';
import 'package:cut_map/common/widgets/custom_compact_barber_card.dart';
import 'package:cut_map/common/widgets/custom_map_preview.dart';
import 'package:cut_map/common/widgets/custom_notification_button.dart';
import 'package:cut_map/common/widgets/custom_profile_avatar.dart';
import 'package:cut_map/common/widgets/custom_text_form_field.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/home/controllers/home_controller.dart';
import 'package:cut_map/features/home/states/section_state.dart';
import 'package:cut_map/locator.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = locator.get<HomeScreenController>();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            toolbarHeight: 70.h,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child:
                  // CABEÇALHO COM NOME E AVATAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ListenableBuilder(
                        listenable: locator.get<AuthManager>(),
                        builder: (context, child) {
                          final userName = locator
                              .get<AuthManager>()
                              .user
                              ?.name;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Olá,",
                                style: AppFonts.regular16.apply(
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                userName ?? "Usuário",
                                style: AppFonts.bold24.apply(
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
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
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40.h),
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child:
                    // PARTE DE LOCALIZAÇÃO ATUAL
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
                          style: AppFonts.medium14.apply(
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),

                  // CAMPO DE PESQUISA
                  CustomTextFormField(
                    hintText: "Pesquisar barbearias",
                    prefixIcon: Icons.search,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  SizedBox(height: 20.h),

                  // SEÇÃO: MAPA (deriva do estado de "próximas a você")
                  ValueListenableBuilder<BarbershopsState>(
                    valueListenable: _controller.nearbyState,
                    builder: (context, state, child) {
                      final List<BarbershopModel> barbearias = switch (state) {
                        SectionSuccessState<List<BarbershopModel>>(
                          :final data,
                        ) =>
                          data,
                        _ => const <BarbershopModel>[],
                      };

                      return CustomMapPreview(
                        centro: _controller.userLocation,
                        barbearias: barbearias,
                        onVerNoMapa: () {},
                      );
                    },
                  ),
                  SizedBox(height: 20.h),

                  // SEÇÃO: PRÓXIMAS A VOCÊ
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
                            style: AppFonts.medium16.apply(
                              color: AppColors.yellow,
                            ),
                          ),
                          const Icon(
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
                  SizedBox(
                    height: CustomCompactBarberCard.cardHeight.h,
                    child: ValueListenableBuilder<BarbershopsState>(
                      valueListenable: _controller.nearbyState,
                      builder: (context, state, child) {
                        return switch (state) {
                          SectionLoadingState() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          SectionErrorState(
                            :final message,
                            :final isServerDown,
                            :final isLocationBlocked,
                          ) =>
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(message, textAlign: TextAlign.center),
                                  if (isLocationBlocked) ...[
                                    SizedBox(height: 10.h),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _controller.openLocationSettings(),
                                      child: const Text('Abrir configurações'),
                                    ),
                                  ] else if (isServerDown) ...[
                                    SizedBox(height: 10.h),
                                    ElevatedButton(
                                      onPressed: () => _controller.loadNearby(),
                                      child: const Text('Tentar novamente'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          SectionSuccessState(:final data) =>
                            data.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Nenhuma barbearia próxima encontrada.',
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      spacing: 8,
                                      children: data
                                          .map(
                                            (
                                              barbershop,
                                            ) => CustomCompactBarberCard(
                                              barberName: barbershop.name,
                                              onTap: () {},
                                              distance:
                                                  barbershop.distanceInKm !=
                                                      null
                                                  ? '${barbershop.distanceInKm!.toStringAsFixed(1)} km'
                                                  : null,
                                              location:
                                                  barbershop.address.bairro,
                                              rating: barbershop.rating,
                                              reviewsCount:
                                                  barbershop.reviewsCount,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                          _ => const SizedBox.shrink(),
                        };
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // SEÇÃO: MAIS BEM AVALIADAS
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
                            style: AppFonts.medium16.apply(
                              color: AppColors.yellow,
                            ),
                          ),
                          const Icon(
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
                  ValueListenableBuilder<BarbershopsState>(
                    valueListenable: _controller.topRatedState,
                    builder: (context, state, child) {
                      return switch (state) {
                        SectionLoadingState() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        SectionErrorState(
                          :final message,
                          :final isServerDown,
                        ) =>
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(message, textAlign: TextAlign.center),
                                if (isServerDown) ...[
                                  SizedBox(height: 10.h),
                                  ElevatedButton(
                                    onPressed: () => _controller.loadTopRated(),
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        SectionSuccessState(:final data) =>
                          data.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhuma barbearia disponível no momento.',
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: data.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: 10.h),
                                  itemBuilder: (context, index) {
                                    final currentBarbershop = data[index];

                                    return CustomBarberCard(
                                      barberName: currentBarbershop.name,
                                      address:
                                          currentBarbershop.address.formatted,
                                      distance:
                                          currentBarbershop.distanceInKm != null
                                          ? '${currentBarbershop.distanceInKm!.toStringAsFixed(1)} km'
                                          : null,
                                    );
                                  },
                                ),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),

                  // INFORMATIVO DE PRÓXIMO AGENDAMENTO
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
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
        ],
      ),
    );
  }
}
