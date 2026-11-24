import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/features/onboarding/services/onboarding_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _OnboardingStepData {
  final String emoji;
  final IconData badgeIcon;
  final String title;
  final String description;

  const _OnboardingStepData({
    required this.emoji,
    required this.badgeIcon,
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
  static const Color _screenBackground = Color(0xFF0A0A0A);
  static const Color _cardSurface = Color(0xFF1A1A1A);
  static const Color _mutedDescription = Color(0xFF9A9AA0);

  static const List<_OnboardingStepData> _steps = [
    _OnboardingStepData(
      emoji: '📍',
      badgeIcon: Icons.location_on_outlined,
      title: 'Barbearias perto de você',
      description:
          'Encontre os melhores lugares com base na sua localização, avaliação e distância.',
    ),
    _OnboardingStepData(
      emoji: '📅',
      badgeIcon: Icons.calendar_today_outlined,
      title: 'Agende em poucos passos',
      description:
          'Escolha o barbeiro, o serviço e o horário ideal. Tudo sem sair do app.',
    ),
    _OnboardingStepData(
      emoji: '⭐',
      badgeIcon: Icons.star_outline_rounded,
      title: 'Avalie e compartilhe',
      description:
          'Deixe sua opinião, favorite as melhores e ajude outros usuários a encontrar o corte perfeito.',
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
    final viewportSize = MediaQuery.maybeSizeOf(context);
    if (viewportSize != null) {
      Sizes.init(context);
    }

    final width = viewportSize?.width ?? 390.0;
    final shortestSide = viewportSize?.shortestSide ?? 390.0;
    final horizontalPadding = (width * 0.06).clamp(16.0, 24.0);
    final heroScale = (shortestSide / 430.0).clamp(0.72, 1.05);
    final titleFontSize = width < 360 ? 24.0 : 28.0;
    final isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _finishOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gray,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Pular',
                    style: AppFonts.medium14.copyWith(color: AppColors.gray),
                  ),
                ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 16 * heroScale,
                                  ),
                                  child: Center(
                                    child: _OnboardingHero(
                                      step: step,
                                      cardSurface: _cardSurface,
                                      scale: heroScale,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 24,
                                    bottom: 24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        textAlign: TextAlign.left,
                                        style: AppFonts.bold26.copyWith(
                                          fontSize: titleFontSize,
                                          height: 1.15,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        step.description,
                                        textAlign: TextAlign.left,
                                        style: AppFonts.regular14.copyWith(
                                          fontSize: 15,
                                          height: 1.45,
                                          color: _mutedDescription,
                                        ),
                                      ),
                                    ],
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_steps.length, (index) {
                      final active = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: active ? 24 : 6,
                        decoration: BoxDecoration(
                          color: active ? AppColors.yellow : AppColors.darkGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onNextOrStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellow,
                            foregroundColor: AppColors.blackDarkGray,
                            disabledBackgroundColor: AppColors.yellow
                                .withValues(alpha: 0.7),
                            elevation: 0,
                            minimumSize: const Size(0, 46),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.blackDarkGray,
                                  ),
                                )
                              : Text(
                                  isLastPage ? 'Começar 🚀' : 'Próximo →',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AppFonts.bold14.copyWith(
                                    fontSize: 15,
                                    color: AppColors.blackDarkGray,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  final _OnboardingStepData step;
  final Color cardSurface;
  final double scale;

  const _OnboardingHero({
    required this.step,
    required this.cardSurface,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 244 * scale,
          height: 224 * scale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 196 * scale,
                height: 196 * scale,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
              Positioned(
                top: 2 * scale,
                right: 6 * scale,
                child: Container(
                  width: 18 * scale,
                  height: 18 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 16 * scale,
                left: 14 * scale,
                child: Container(
                  width: 34 * scale,
                  height: 34 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 4 * scale,
                right: 22 * scale,
                child: Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(
                width: 168 * scale,
                height: 168 * scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Container(
                        width: 148 * scale,
                        height: 148 * scale,
                        decoration: BoxDecoration(
                          color: cardSurface,
                          borderRadius: BorderRadius.circular(28 * scale),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            step.emoji,
                            style: TextStyle(fontSize: 48 * scale),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 44 * scale,
                        height: 44 * scale,
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(14 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          step.badgeIcon,
                          size: 22 * scale,
                          color: AppColors.blackDarkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * scale),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.content_cut_rounded,
                size: 14,
                color: AppColors.blackDarkGray,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'cut_map',
              style: AppFonts.bold14.copyWith(
                color: AppColors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
