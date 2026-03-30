import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/widgets/custom_password_form_field.dart';
import 'package:cut_map/commom/widgets/custom_primary_buttom.dart';
import 'package:cut_map/commom/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
                      onPressed: () {},
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 20.s,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
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
              child: Column(
                children: [
                  CustomTextFormField(hintText: "username", labelText: "Nome"),
                  CustomTextFormField(
                    hintText: "e-mail",
                    labelText: "E-mail",
                    textInputType: TextInputType.emailAddress,
                  ),
                  CustomPasswordFormField(
                    hintText: "••••••••",
                    labelText: "Password",
                  ),
                  CustomTextFormField(
                    hintText: "••••••••",
                    labelText: "Confirm Password",
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
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: CustomPrimaryButtom(
                text: "Cria Conta",
                color: AppColors.yellow,
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
                  onTap: () {},
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
