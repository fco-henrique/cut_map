import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/common/validators/inputs_validator.dart';
import 'package:cut_map/common/widgets/custom_password_form_field.dart';
import 'package:cut_map/common/widgets/custom_primary_buttom.dart';
import 'package:cut_map/common/widgets/custom_snackbar.dart';
import 'package:cut_map/features/auth/controllers/change_password_controller.dart';
import 'package:cut_map/features/auth/states/change_password_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String resetToken;

  const ChangePasswordScreen({super.key, required this.resetToken});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _controller = locator.get<ChangePasswordScreenController>();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final state = _controller.state;

      if (state is ChangePasswordScreenSuccessState) {
        context.go(NamedRoutes.signIn);
      } else if (state is ChangePasswordScreenErrorState) {
        CustomSnackbar.show(
          context,
          title: state.isServerDown
              ? "Servidor Indisponível"
              : "Falha ao alterar senha",
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.yellow,
              height: 150.h,
              width: double.infinity,
            ),

            SizedBox(height: 20.h),
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
                    "Altere sua senha",
                    style: AppFonts.bold26.apply(color: AppColors.white),
                  ),
                ],
              ),
            ),

            SizedBox(height: 70.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
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

            SizedBox(height: 55.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return CustomPrimaryButtom(
                    text: "Alterar senha",
                    color: AppColors.yellow,
                    isLoading: _controller.state is ChangePasswordScreenLoadingState,
                    onPressed: () {
                      final valid = _formKey.currentState?.validate() ?? false;

                      if (valid) {
                        _controller.resetPassword(
                          resetToken: widget.resetToken,
                          newPassword: _passwordController.text,
                        );
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
