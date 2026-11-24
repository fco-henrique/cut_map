import { ArgumentMetadata, ValidationPipe } from '@nestjs/common';
import { LoginDto } from './login.dto';

const metadata: ArgumentMetadata = { type: 'body', metatype: LoginDto };

// Mesma configuração do ValidationPipe global (src/main.ts).
const pipe = new ValidationPipe({
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
});

const email = 'user@example.com';

describe('LoginDto (senha não é normalizada)', () => {
  it.each([
    ['espaço no início', ' SenhaForte1!'],
    ['espaço no fim', 'SenhaForte1! '],
    ['espaços nas duas pontas', '  SenhaForte1!  '],
    ['espaço no meio', 'Senha Forte1!'],
    ['tabulação e quebra de linha nas pontas', '\tSenhaForte1!\n'],
  ])(
    'preserva a senha exatamente como enviada (%s)',
    async (_name, password) => {
      const result = (await pipe.transform(
        { email, password },
        metadata,
      )) as LoginDto;

      expect(result).toBeInstanceOf(LoginDto);
      expect(result.password).toBe(password);
      expect(result.password).toHaveLength(password.length);
    },
  );

  it('aceita senha composta só por espaços sem alterá-la (a verificação é do hash)', async () => {
    const result = (await pipe.transform(
      { email, password: '   ' },
      metadata,
    )) as LoginDto;
    expect(result.password).toBe('   ');
  });

  it.each([
    ['vazia', ''],
    ['ausente', undefined],
    ['nula', null],
    ['número', 12345678],
  ])('continua rejeitando senha %s', async (_name, password) => {
    await expect(
      pipe.transform({ email, password }, metadata),
    ).rejects.toThrow();
  });
});
