import 'dart:async';

import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/widgets/custom_barber_card.dart';
import 'package:cut_map/common/widgets/custom_compact_barber_card.dart';
import 'package:cut_map/common/widgets/custom_map_preview.dart';
import 'package:cut_map/common/widgets/custom_notification_button.dart';
import 'package:cut_map/common/widgets/custom_text_form_field.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/features/home/controllers/home_controller.dart';
import 'package:cut_map/features/home/screens/full_map_screen.dart';
import 'package:cut_map/features/home/states/section_state.dart';
import 'package:cut_map/locator.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = locator.get<HomeScreenController>();
  late final Timer _clockTimer;

  void _onBarbershopTap(BarbershopModel barbershop) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalhes de ${barbershop.name} em breve.')),
    );
  }

  String? _distanceLabel(BarbershopModel barbershop) {
    final km = barbershop.distanceFrom(_controller.currentLocation.value);
    return km == null ? null : '${km.toStringAsFixed(1)} km';
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

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
                    readOnly: true,
                    onTap: widget.onExplore,
                  ),
                  SizedBox(height: 20.h),

                  // SEÇÃO: MAPA (deriva do estado de "próximas a você")
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      _controller.nearbyState,
                      _controller.currentLocation,
                    ]),
                    builder: (context, child) {
                      final List<BarbershopModel> barbearias = switch (
                          _controller.nearbyState.value) {
                        SectionSuccessState<List<BarbershopModel>>(
                          :final data,
                        ) =>
                          data,
                        _ => const <BarbershopModel>[],
                      };

                      return CustomMapPreview(
                        centro: _controller.userLocation,
                        userLocation: _controller.currentLocation.value,
                        barbearias: barbearias,
                        onBarbershopTap: _onBarbershopTap,
                        onVerNoMapa: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FullMapScreen(
                                barbearias: barbearias,
                                centro: _controller.userLocation,
                                userLocation: _controller.currentLocation.value,
                                onBarbershopTap: _onBarbershopTap,
                              ),
                            ),
                          );
                        },
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
                      InkWell(
                        onTap: widget.onExplore,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text('Ver todas ',
                                  style: AppFonts.medium16.apply(color: AppColors.yellow)),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.yellow),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // CARDS DE BARBEARIAS COMPACTAS
                  SizedBox(
                    height: CustomCompactBarberCard.cardHeight.h,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        _controller.nearbyState,
                        _controller.currentLocation,
                      ]),
                      builder: (context, child) {
                        final state = _controller.nearbyState.value;
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
                                              onTap: () => _onBarbershopTap(barbershop),
                                              distance: _distanceLabel(barbershop),
                                              isOpen: barbershop.isOpenAt(DateTime.now()),
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
                      InkWell(
                        onTap: widget.onExplore,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text('Ver todas ',
                                  style: AppFonts.medium16.apply(color: AppColors.yellow)),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.yellow),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // CARDS DE BARBEARIAS
                  SizedBox(height: 10.h),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      _controller.topRatedState,
                      _controller.currentLocation,
                    ]),
                    builder: (context, child) {
                      final state = _controller.topRatedState.value;
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
                                      rating: currentBarbershop.rating,
                                      reviewsCount: currentBarbershop.reviewsCount,
                                      isOpen: currentBarbershop.isOpenAt(DateTime.now()),
                                      workingHours:
                                          currentBarbershop.hoursLabelAt(DateTime.now()),
                                      address:
                                          currentBarbershop.address.formatted,
                                      distance: _distanceLabel(currentBarbershop),
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
