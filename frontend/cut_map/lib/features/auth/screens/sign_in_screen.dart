import 'dart:developer';

import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/commom/validators/inputs_validator.dart';
import 'package:cut_map/commom/widgets/custom_password_form_field.dart';
import 'package:cut_map/commom/widgets/custom_primary_buttom.dart';
import 'package:cut_map/commom/widgets/custom_text_form_field.dart';
import 'package:cut_map/features/auth/controllers/sign_in_controller.dart';
import 'package:cut_map/features/auth/states/sign_in_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = locator.get<SignInScreenController>();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.state is SignInSuccessState) {
        context.push(NamedRoutes.welcome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.yellow,
              height: 350.h,
              width: double.infinity,
            ),
            SizedBox(height: 30.h),

            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bem-vindo de volta!",
                    style: AppFonts.bold26.apply(color: AppColors.white),
                  ),
                  Text(
                    "Faça login para continuar",
                    style: AppFonts.regular16.apply(color: AppColors.gray),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextFormField(
                    labelText: "Email",
                    hintText: "user@email.com",
                    textInputType: TextInputType.emailAddress,
                    validator: InputsValidator.email,
                    textEditingController: _emailController,
                  ),
                  CustomPasswordFormField(
                    labelText: "Senha",
                    hintText: "••••••••",
                    validator: InputsValidator.password,
                    textEditingController: _passwordController,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.push(NamedRoutes.emailVerify);
                    },
                    child: Text(
                      "Esqueceu sua senha?",
                      style: AppFonts.medium14.apply(color: AppColors.yellow),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: CustomPrimaryButtom(
                text: "Entrar",
                color: AppColors.yellow,
                onPressed: () {
                  final valid = _formKey.currentState?.validate() ?? false;

                  if (valid) {
                    log("Prosseguindo com o login");
                    _controller.signIn(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                  } else {
                    log("Falha no login");
                  }
                },
              ),
            ),

            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Não tem conta ainda? ",
                  style: AppFonts.regular14.apply(color: AppColors.gray),
                ),
                GestureDetector(
                  onTap: () {
                    context.push(NamedRoutes.signUp);
                  },
                  child: Text(
                    "Criar Conta",
                    style: AppFonts.bold14.apply(color: AppColors.yellow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
