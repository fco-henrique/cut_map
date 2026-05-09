import 'dart:async';
import 'dart:developer';

import 'package:cut_map/app.dart';
import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/commom/validators/inputs_validator.dart';
import 'package:cut_map/commom/widgets/custom_codig_form_field.dart';
import 'package:cut_map/commom/widgets/custom_primary_buttom.dart';
import 'package:cut_map/commom/widgets/custom_snackbar.dart';
import 'package:cut_map/features/auth/controllers/verify_email_controller.dart';
import 'package:cut_map/features/auth/states/verify_email_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final VerificationContext context;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.context,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codigController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<VerifyEmailScreenController>();

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

    _controller.addListener(() {
      final state = _controller.state;

      if (state is VerifyEmailScreenSuccessState) {
        context.go(NamedRoutes.welcome);
      } else if (state is VerifyEmailScreenResendSuccessState) {
        CustomSnackbar.show(
          context,
          title: "Código Reenviado",
          message: "Verifique sua caixa de entrada e spam.",
          type: SnackbarType.success,
        );
      } else if (state is VerifyEmailScreenResetSuccessState) {
        context.push(NamedRoutes.changePassword, extra: state.resetToken);
      } else if (state is VerifyEmailScreenErrorState) {
        CustomSnackbar.show(
          context,
          title: state.isServerDown
              ? "Servidor Indisponível"
              : "Falha na Verificação",
          message: state.message,
          type: state.isServerDown
              ? SnackbarType.unavailable
              : SnackbarType.error,
        );
      }
    });
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
                      onPressed: () {
                        if (widget.context == VerificationContext.signUp) {
                          context.pop();
                        } else if (widget.context ==
                            VerificationContext.forgotPassword) {
                          context.go(NamedRoutes.sendEmail);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.white,
                        size: 20.s,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    widget.context == VerificationContext.signUp
                        ? "Validar E-mail"
                        : "Validar E-mail para recuperação",
                    style: AppFonts.semiBold20.apply(color: AppColors.white),
                  ),
                ],
              ),
            ),

            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
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
                          text: widget.email,
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
              padding: EdgeInsets.symmetric(horizontal: 24),
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
              padding: EdgeInsets.symmetric(horizontal: 24),
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
                                _controller.resendVerificationEmail(
                                  widget.email,
                                );
                              }
                            : null,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return CustomPrimaryButtom(
                    text: "Verificar",
                    color: AppColors.yellow,
                    isLoading: _controller.state is VerifyEmailScreenLoadingState,
                    onPressed: () {
                      final valid = _formKey.currentState?.validate() ?? false;

                      if (valid) {
                        final code = _codigController.text;

                        if (widget.context == VerificationContext.signUp) {
                          log("Verificando código de CADASTRO");
                          _controller.verifyEmail(widget.email, code);
                        } else if (widget.context ==
                            VerificationContext.forgotPassword) {
                          log("Verificando código de RECUPERAÇÃO DE SENHA");
                          _controller.verifyResetPasswordCode(
                            widget.email,
                            code,
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
