import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/validators/inputs_validator.dart';
import 'package:cut_map/common/widgets/custom_password_form_field.dart';
import 'package:cut_map/common/widgets/custom_primary_buttom.dart';
import 'package:cut_map/common/widgets/custom_snackbar.dart';
import 'package:cut_map/features/auth/controllers/update_password_controller.dart';
import 'package:cut_map/features/auth/states/update_password_state.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpdatePasswordScreen extends StatefulWidget {
  final UpdatePasswordController? controller;

  const UpdatePasswordScreen({super.key, this.controller});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final UpdatePasswordController _controller;
  late final bool _ownsController;

  void _onControllerChanged() {
    if (!mounted) return;
    final state = _controller.state;

    if (state is UpdatePasswordSuccessState) {
      CustomSnackbar.show(
        context,
        title: 'Senha atualizada',
        message: 'Sua senha foi alterada com sucesso.',
        type: SnackbarType.success,
      );
      if (context.canPop()) {
        context.pop();
      }
    } else if (state is UpdatePasswordErrorState) {
      CustomSnackbar.show(
        context,
        title: state.isServerDown
            ? 'Servidor Indisponível'
            : 'Falha ao alterar senha',
        message: state.message,
        type: state.isServerDown
            ? SnackbarType.unavailable
            : SnackbarType.error,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? locator.get<UpdatePasswordController>();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Sizes().width == 0 || Sizes().height == 0) {
      Sizes.init(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 40.h,
                      width: 50.w,
                      decoration: const BoxDecoration(
                        color: AppColors.darkGray,
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: 20.s,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Alterar senha',
                      style: AppFonts.bold26.apply(color: AppColors.white),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Informe sua senha atual e defina uma nova senha segura.',
                      style: AppFonts.regular16.apply(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomPasswordFormField(
                      hintText: '••••••••',
                      labelText: 'Senha atual',
                      validator: InputsValidator.currentPassword,
                      textEditingController: _currentPasswordController,
                    ),
                    CustomPasswordFormField(
                      hintText: '••••••••',
                      labelText: 'Nova senha',
                      validator: InputsValidator.password,
                      textEditingController: _newPasswordController,
                    ),
                    CustomPasswordFormField(
                      hintText: '••••••••',
                      labelText: 'Confirmar nova senha',
                      validator: InputsValidator.comparePassword(
                        _newPasswordController,
                      ),
                      textEditingController: _confirmPasswordController,
                      canTogglePassword: false,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) {
                    return CustomPrimaryButtom(
                      text: 'Salvar nova senha',
                      color: AppColors.yellow,
                      isLoading:
                          _controller.state is UpdatePasswordLoadingState,
                      onPressed: () {
                        final valid =
                            _formKey.currentState?.validate() ?? false;
                        if (valid) {
                          _controller.updatePassword(
                            currentPassword: _currentPasswordController.text,
                            newPassword: _newPasswordController.text,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
