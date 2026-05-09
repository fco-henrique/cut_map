import 'package:flutter/widgets.dart';
import 'package:validatorless/validatorless.dart';

class InputsValidator {
  InputsValidator._();

  static FormFieldValidator<String> get name =>
      Validatorless.required('Nome é obrigatório');

  static FormFieldValidator<String> get email => Validatorless.multiple([
    Validatorless.required('E-mail é obrigatório'),
    Validatorless.email('E-mail inválido'),
  ]);

  static FormFieldValidator<String> get password => Validatorless.multiple([
    Validatorless.required('Senha é obrigatória'),
    Validatorless.min(8, 'A senha deve ter pelo menos 8 caracteres'),
    Validatorless.regex(
      RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
      ),
      'A senha deve conter pelo menos uma letra maiúscula, uma letra minúscula, um número e um caractere especial',
    ),
  ]);

  static FormFieldValidator<String> get passwordLogin => Validatorless.multiple([
    Validatorless.required('Senha é obrigatória'),
  ]);

  static FormFieldValidator<String> comparePassword(
    TextEditingController controller,
  ) {
    return Validatorless.multiple([
      Validatorless.required('Confirmar Senha é obrigatório'),
      Validatorless.compare(controller, 'As senhas não conferem'),
    ]);
  }

  static FormFieldValidator<String> get codig => Validatorless.multiple([
    Validatorless.required('Este campo é obrigatório'),
    Validatorless.min(6, 'O código deve ter 6 caracteres'),
    Validatorless.regex(
      RegExp(r'^[a-zA-Z0-9]+$'),
      'O código deve ser composto apenas por letras e números',
    ),
  ]);
}
