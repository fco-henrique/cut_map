import 'dart:developer';

import 'package:cut_map/app.dart';
import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/commom/widgets/custom_password_form_field.dart';
import 'package:cut_map/commom/widgets/custom_primary_buttom.dart';
import 'package:cut_map/commom/widgets/custom_snackbar.dart';
import 'package:cut_map/commom/widgets/custom_text_form_field.dart';
import 'package:cut_map/commom/validators/inputs_validator.dart';
import 'package:cut_map/features/auth/controllers/sign_up_controller.dart';
import 'package:cut_map/features/auth/states/sign_up_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final _controller = locator.get<SignUpScreenController>();

  @override
  void initState() {
    _controller.addListener(() {
      final state = _controller.state;

      if (state is SignUpScreenSuccessState) {
        context.push(
          NamedRoutes.emailVerify,
          extra: {
            'email': _emailController.text.trim(),
            'context': VerificationContext.signUp,
          },
        );
      } else if (state is SignUpScreenErrorState) {
        CustomSnackbar.show(
          context,
          title: state.isServerDown
              ? 'Servidor Indisponível'
              : 'Falha no Cadastro',
          message: state.message,
          type: state.isServerDown
              ? SnackbarType.unavailable
              : SnackbarType.error,
        );
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
            SizedBox(height: 80.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: AppColors.darkGray,
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 20.s,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Cria conta",
                    style: AppFonts.bold26.apply(color: AppColors.white),
                  ),
                  Text(
                    "Junte-se a comunidade cut_map",
                    style: AppFonts.regular16.apply(color: AppColors.gray),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextFormField(
                    hintText: "username",
                    labelText: "Nome",
                    validator: InputsValidator.name,
                    textEditingController: _nameController,
                  ),
                  CustomTextFormField(
                    hintText: "e-mail",
                    labelText: "E-mail",
                    textInputType: TextInputType.emailAddress,
                    validator: InputsValidator.email,
                    textEditingController: _emailController,
                  ),
                  CustomPasswordFormField(
                    hintText: "••••••••",
                    labelText: "Password",
                    validator: InputsValidator.password,
                    textEditingController: _passwordController,
                  ),
                  CustomPasswordFormField(
                    hintText: "••••••••",
                    labelText: "Confirm Password",
                    validator: InputsValidator.comparePassword(
                      _passwordController,
                    ),
                    textEditingController: _confirmPasswordController,
                    canTogglePassword: false,
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Ao criar sua conta, você concorda com nossos ",
                  style: AppFonts.regular12.apply(color: AppColors.gray),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    "Termos de Uso",
                    style: AppFonts.bold12.apply(color: AppColors.yellow),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "e ",
                  style: AppFonts.regular12.apply(color: AppColors.gray),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    "Política de Privacidade  ",
                    style: AppFonts.bold12.apply(color: AppColors.yellow),
                  ),
                ),
              ],
            ),

            SizedBox(height: 55.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return CustomPrimaryButtom(
                    text: "Cria Conta",
                    color: AppColors.yellow,
                    isLoading: _controller.state is SignUpScreenLoadingState,
                    onPressed: () {
                      final valid = _formKey.currentState?.validate() ?? false;

                      if (valid) {
                        log("prosseguindo com a criação da conta");
                        _controller.signUp(
                          name: _nameController.text,
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                      }
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Já tem conta? ",
                  style: AppFonts.regular14.apply(color: AppColors.gray),
                ),
                GestureDetector(
                  onTap: () {
                    context.push(NamedRoutes.signIn);
                  },
                  child: Text(
                    "Entrar",
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
