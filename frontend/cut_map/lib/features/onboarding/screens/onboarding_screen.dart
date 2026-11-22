import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/common/widgets/custom_primary_buttom.dart';
import 'package:cut_map/features/onboarding/services/onboarding_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _OnboardingStepData {
  final IconData icon;
  final String badge;
  final String title;
  final String description;

  const _OnboardingStepData({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  final OnboardingManager? onboardingManager;

  const OnboardingScreen({super.key, this.onboardingManager});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingStepData> _steps = [
    _OnboardingStepData(
      icon: Icons.location_on_rounded,
      badge: 'Explorar',
      title: 'Encontre barbearias próximas',
      description:
          'Descubra barbearias perto de você no mapa interativo, veja horários de funcionamento e distância em tempo real.',
    ),
    _OnboardingStepData(
      icon: Icons.calendar_month_rounded,
      badge: 'Agendar',
      title: 'Agendamento sem complicação',
      description:
          'Escolha seu serviço favorito, selecione o melhor horário e confirme seu atendimento em poucos toques.',
    ),
    _OnboardingStepData(
      icon: Icons.star_rounded,
      badge: 'Avaliar',
      title: 'Avaliações reais de clientes',
      description:
          'Compare notas e comentários da comunidade para escolher a barbearia ideal com total confiança.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  OnboardingManager get _manager =>
      widget.onboardingManager ?? locator.get<OnboardingManager>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _manager.completeOnboarding();
      if (mounted) {
        context.go(NamedRoutes.signIn);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onNextOrStart() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Sizes().width == 0 || Sizes().height == 0) {
      Sizes.init(context);
    }

    final isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cut Map',
                    style: AppFonts.bold18.apply(color: AppColors.yellow),
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : _finishOnboarding,
                    child: Text(
                      'Pular',
                      style: AppFonts.medium16.apply(color: AppColors.lightGray),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 150.s,
                                  height: 150.s,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkGray,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.yellow.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 92.s,
                                      height: 92.s,
                                      decoration: BoxDecoration(
                                        color: AppColors.yellow.withValues(
                                          alpha: 0.14,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        step.icon,
                                        size: 48.s,
                                        color: AppColors.yellow,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 28.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkGray,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    step.badge,
                                    style: AppFonts.semiBold12.apply(
                                      color: AppColors.yellow,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Text(
                                  step.title,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.bold26.apply(
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  step.description,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.regular16.apply(
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    height: 8.h,
                    width: active ? 26.w : 8.w,
                    decoration: BoxDecoration(
                      color: active ? AppColors.yellow : AppColors.darkGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              SizedBox(height: 28.h),
              CustomPrimaryButtom(
                text: isLastPage ? 'Começar' : 'Próximo',
                color: AppColors.yellow,
                isLoading: _isSubmitting,
                onPressed: _onNextOrStart,
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
