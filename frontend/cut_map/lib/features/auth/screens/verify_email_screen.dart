import 'dart:async';
import 'dart:developer';

import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/validators/inputs_validator.dart';
import 'package:cut_map/commom/widgets/custom_codig_form_field.dart';
import 'package:cut_map/commom/widgets/custom_primary_buttom.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codigController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 80.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
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
                  SizedBox(width: 20.w),
                  Text(
                    "Validar E-mail",
                    style: AppFonts.semiBold20.apply(color: AppColors.white),
                  ),
                ],
              ),
            ),

            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Digite o código",
                    style: AppFonts.bold26.apply(color: AppColors.white),
                  ),
                  SizedBox(height: 6.h),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Enviamos um código para: ",
                          style: AppFonts.regular16.apply(
                            color: AppColors.gray,
                          ),
                        ),
                        TextSpan(
                          text: "hevs0015@email.com",
                          style: AppFonts.regular16.apply(
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 60.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: CustomCodigFormField(
                  validator: InputsValidator.codig,
                  controller: _codigController,
                ),
              ),
            ),

            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Não recebeu o código? ",
                      style: AppFonts.regular16.apply(color: AppColors.gray),
                    ),
                    TextSpan(
                      text: _canResend ? "Reenviar" : "Reenviar em ${_start}s",
                      style: AppFonts.bold16.apply(
                        color: _canResend ? AppColors.yellow : AppColors.gray,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _canResend
                            ? () {
                                startTimer();
                              }
                            : null,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: CustomPrimaryButtom(
                text: "Verificar",
                color: AppColors.yellow,
                onPressed: () {
                  final valid = _formKey.currentState?.validate() ?? false;

                  if (valid) {
                    log("Verificar código: ${_codigController.text}");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
