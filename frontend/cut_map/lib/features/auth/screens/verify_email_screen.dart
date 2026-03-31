import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Verifique seu email para continuar',
          style: TextStyle(fontSize: 18, color: AppColors.yellow),
        ),
      ),
    );
  }
}
