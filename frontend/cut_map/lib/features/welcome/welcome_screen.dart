import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            CustomSnackbar.show(
              context,
              title: 'Saved Successfully',
              message: 'Your changes have been saved successfully',
              type: SnackbarType.unavailable,
            );
          },
          child: const Text('Salvar'),
        ),
      ),
    );
  }
}
