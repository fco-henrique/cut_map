import 'package:cut_map/common/validators/inputs_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputsValidator.password', () {
    final validator = InputsValidator.password;

    test('rejeita senha vazia ou menor que 8 caracteres', () {
      expect(validator(''), isNotNull);
      expect(validator(null), isNotNull);
      expect(validator('Ab1!xyz'), isNotNull);
    });

    test('rejeita senha sem maiúscula, minúscula, número ou especial', () {
      expect(validator('abcdef1!'), isNotNull); // sem maiúscula
      expect(validator('ABCDEF1!'), isNotNull); // sem minúscula
      expect(validator('Abcdefg!'), isNotNull); // sem número
      expect(validator('Abcdef12'), isNotNull); // sem especial
      expect(validator('Abcdef1 '), isNotNull); // espaço não é especial
    });

    test('aceita senha forte com qualquer caractere especial não alfanumérico', () {
      expect(validator('Abcd123!'), isNull);
      expect(validator('Abcd123#'), isNull);
      expect(validator('Abcd123_'), isNull);
      expect(validator('Abcd123-'), isNull);
      expect(validator('Senha@2026'), isNull);
      expect(validator('Str0ng.Pass+1'), isNull);
    });
  });

  group('InputsValidator auxiliares', () {
    test('valida nome com mínimo de 3 caracteres', () {
      expect(InputsValidator.name(''), isNotNull);
      expect(InputsValidator.name('Ab'), isNotNull);
      expect(InputsValidator.name('Ana'), isNull);
    });

    test('valida e-mail obrigatório e formato', () {
      expect(InputsValidator.email(''), isNotNull);
      expect(InputsValidator.email('invalido'), isNotNull);
      expect(InputsValidator.email('user@cutmap.dev'), isNull);
    });

    test('valida senha atual obrigatória', () {
      expect(InputsValidator.currentPassword(''), isNotNull);
      expect(InputsValidator.currentPassword('qualquer'), isNull);
    });

    test('valida confirmação de senha igual ao controlador', () {
      final controller = TextEditingController(text: 'Abcd123#');
      addTearDown(controller.dispose);
      final compare = InputsValidator.comparePassword(controller);
      expect(compare(''), isNotNull);
      expect(compare('Diferente1#'), isNotNull);
      expect(compare('Abcd123#'), isNull);
    });
  });
}
