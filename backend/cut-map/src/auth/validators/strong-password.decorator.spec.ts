import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ResetPasswordDto } from '../dto/reset-password.dto';
import { CreateUserDto } from 'src/user/dto/create-user.dto';
import { UpdateUserDto } from 'src/user/dto/update-user.dto';
import { STRONG_PASSWORD_MESSAGE } from './strong-password.decorator';

const VALID_PASSWORDS = [
  'Abcdef1!',
  'SenhaForte123!',
  'Senha_Forte9',
  'Ação-Segura7',
  'a1B2c3d4#extra-longa',
];

const INVALID_PASSWORDS: [string, unknown][] = [
  ['vazia', ''],
  ['só espaços', '        '],
  ['curta (7)', 'Abcde1!'],
  ['sem maiúscula', 'abcdef1!'],
  ['sem minúscula', 'ABCDEF1!'],
  ['sem número', 'Abcdefg!'],
  ['sem especial', 'Abcdefg1'],
  ['espaço não conta como especial', 'Abcdef1 x'],
  ['só letras e números acentuados', 'Ação1234'],
  ['antiga regra de 6 caracteres', 'Ab1!x'],
  ['número', 12345678],
  ['nulo', null],
];

const base = { name: 'Maria Silva', email: 'maria@example.com' };

async function errorsFor<T extends object>(
  cls: new () => T,
  payload: Record<string, unknown>,
  field: string,
) {
  const errors = await validate(plainToInstance(cls, payload));
  return errors.find(e => e.property === field)?.constraints;
}

describe('política de senha forte', () => {
  describe.each([
    [
      'CreateUserDto (cadastro)',
      (password: unknown) =>
        errorsFor(CreateUserDto, { ...base, password }, 'password'),
    ],
    [
      'ResetPasswordDto (recuperação)',
      (password: unknown) =>
        errorsFor(ResetPasswordDto, { newPassword: password }, 'newPassword'),
    ],
    [
      'UpdateUserDto (alteração)',
      (password: unknown) =>
        errorsFor(
          UpdateUserDto,
          { password, currentPassword: 'Atual123!' },
          'password',
        ),
    ],
  ])('%s', (label, check) => {
    it.each(VALID_PASSWORDS)('aceita "%s"', async password => {
      expect(await check(password)).toBeUndefined();
    });

    it.each(INVALID_PASSWORDS)('rejeita senha %s', async (_name, password) => {
      const constraints = await check(password);
      expect(constraints).toBeDefined();
      expect(Object.values(constraints!)).toContain(STRONG_PASSWORD_MESSAGE);
    });

    it('trata campo ausente conforme o endpoint', async () => {
      const constraints = await check(undefined);
      if (label.startsWith('UpdateUserDto')) {
        expect(constraints).toBeUndefined();
      } else {
        expect(constraints).toBeDefined();
      }
    });
  });

  it('emite a mensagem de senha fraca apenas uma vez por violação', async () => {
    const constraints = await errorsFor(
      CreateUserDto,
      { ...base, password: 'abc' },
      'password',
    );
    expect(Object.values(constraints!)).toEqual([STRONG_PASSWORD_MESSAGE]);
  });

  it('UpdateUserDto continua aceitando atualização apenas de nome', async () => {
    const errors = await validate(
      plainToInstance(UpdateUserDto, { name: 'Novo Nome' }),
    );
    expect(errors).toHaveLength(0);
  });

  it('UpdateUserDto exige a senha atual ao informar nova senha', async () => {
    const constraints = await errorsFor(
      UpdateUserDto,
      { password: 'NovaSenha1!' },
      'currentPassword',
    );
    expect(constraints).toBeDefined();
  });
});
