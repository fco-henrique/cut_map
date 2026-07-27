import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/widgets/custom_barber_card.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Home",
              style: AppFonts.bold26.apply(color: AppColors.white),
            ),
          ),
          SizedBox(height: 100.h),
          ElevatedButton(
            onPressed: () async {
              final authManager = locator.get<AuthManager>();
              await authManager.logout();
            },
            child: const Text('Sair'),
          ),
          CustomBarberCard(),
        ],
      ),
    );
  }
}
