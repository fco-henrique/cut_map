import 'package:cut_map/app.dart';
import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/routes/named_routes.dart';
import 'package:cut_map/commom/validators/inputs_validator.dart';
import 'package:cut_map/commom/widgets/custom_primary_buttom.dart';
import 'package:cut_map/commom/widgets/custom_snackbar.dart';
import 'package:cut_map/commom/widgets/custom_text_form_field.dart';
import 'package:cut_map/features/auth/controllers/send_email_controller.dart';
import 'package:cut_map/features/auth/states/send_email_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SendEmailScreen extends StatefulWidget {
  const SendEmailScreen({super.key});

  @override
  State<SendEmailScreen> createState() => _SendEmailScreenState();
}

class _SendEmailScreenState extends State<SendEmailScreen> {
  final _emailController = TextEditingController();

  final _controller = locator.get<SendEmailScreenController>();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final state = _controller.state;

      if (state is SendEmailScreenSuccessState) {
        context.go(
          NamedRoutes.emailVerify,
          extra: {
            'email': _emailController.text.trim(),
            'context': VerificationContext.forgotPassword,
          },
        );
      } else if (state is SendEmailScreenErrorState) {
        CustomSnackbar.show(
          context,
          title: state.isServerDown
              ? 'Servidor Indisponível'
              : 'Falha ao enviar e-mail',
          message: state.message,
          type: state.isServerDown
              ? SnackbarType.unavailable
              : SnackbarType.error,
        );
      }
    });
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
            Container(
              color: AppColors.yellow,
              height: 150.h,
              width: double.infinity,
            ),

            SizedBox(height: 20.h),
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

            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Digite seu e-mail",
                    style: AppFonts.bold26.apply(color: AppColors.white),
                  ),
                  SizedBox(height: 6.h),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              "Enviaremos um código para seu e-mail, por favor verifique sua caixa de entrada.",
                          style: AppFonts.regular16.apply(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 50.h),
            Form(
              key: _formKey,
              child: CustomTextFormField(
                validator: InputsValidator.email,
                textEditingController: _emailController,
              ),
            ),

            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: CustomPrimaryButtom(
                text: "Verificar",
                color: AppColors.yellow,
                onPressed: () {
                  final valid = _formKey.currentState?.validate() ?? false;

                  if (valid) {
                    _controller.forgotPassword(_emailController.text);
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
