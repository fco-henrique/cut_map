import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ElevatedButton(
          onPressed: ()  async {
            final authManager = locator.get<AuthManager>();            
            await authManager.logout();
          },
          child: const Text('Sair'),
        ),
      ),
    );
  }
}
