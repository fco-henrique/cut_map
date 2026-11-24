/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { EmailService } from 'src/email/email.service';
import { JwtAuthGuard } from 'src/auth/guard/jwt-auth.guard';
import { DockerPostgresHelper } from './helpers/docker-postgres.helper';
import { FakeEmailAdapter } from './helpers/fake-email.adapter';

const STRONG_PASSWORD_MESSAGE =
  'A senha deve ter no mínimo 8 caracteres, com letra maiúscula, letra minúscula, número e caractere especial.';

const WEAK_PASSWORDS: [string, string][] = [
  ['curta', 'Ab1!xyz'],
  ['sem maiúscula', 'senhafraca1!'],
  ['sem minúscula', 'SENHAFRACA1!'],
  ['sem número', 'SenhaFraca!!'],
  ['sem caractere especial', 'SenhaFraca123'],
  ['regra antiga de 6 caracteres', 'abc123'],
];

describe('S2: política de senha forte (cadastro, recuperação e alteração)', () => {
  let app: INestApplication;
  let dbHelper: DockerPostgresHelper;
  let fakeEmail: FakeEmailAdapter;
  let seq = 0;

  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    dbHelper = new DockerPostgresHelper();
    await dbHelper.start();

    // AppModule só pode ser carregado depois que o helper define process.env.
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { AppModule } = require('src/app.module');
    fakeEmail = new FakeEmailAdapter();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(EmailService)
      .useValue(fakeEmail)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalGuards(new JwtAuthGuard(app.get(Reflector)));
    await app.init();
  }, 90000);

  afterAll(async () => {
    if (app) await app.close();
    if (dbHelper) dbHelper.stop();
  }, 30000);

  function newUserData(password = 'SenhaForte123!') {
    seq += 1;
    return {
      name: `Usuário S2 ${seq}`,
      email: `s2.user${seq}@synthetic.cutmap.test`,
      password,
    };
  }

  async function registerAndVerify(password = 'SenhaForte123!') {
    const data = newUserData(password);
    const reg = await http().post('/user').send(data).expect(201);
    const code = fakeEmail.getLatestVerificationCode(data.email)!;
    const verified = await http()
      .post('/auth/verify-email')
      .send({ email: data.email, code })
      .expect(201);
    return {
      ...data,
      id: reg.body.user.id as string,
      accessToken: verified.body.accessToken as string,
      refreshToken: verified.body.refreshToken as string,
    };
  }

  const login = (email: string, password: string) =>
    http().post('/auth/login').send({ email, password });

  describe('US-001 / #7 — cadastro (POST /user)', () => {
    it.each(WEAK_PASSWORDS)(
      'rejeita senha %s com 400 e não cria a conta',
      async (_label, password) => {
        const data = newUserData(password);
        const res = await http().post('/user').send(data);

        expect(res.status).toBe(400);
        expect(res.body.message).toContain(STRONG_PASSWORD_MESSAGE);

        // Nada foi persistido: o mesmo e-mail ainda pode ser cadastrado.
        await http()
          .post('/user')
          .send({ ...data, password: 'SenhaForte123!' })
          .expect(201);
      },
    );

    it('rejeita dados inválidos (e-mail inválido, e-mail ausente, nome curto)', async () => {
      const data = newUserData();
      const invalidEmail = await http()
        .post('/user')
        .send({ ...data, email: 'nao-e-email' });
      expect(invalidEmail.status).toBe(400);

      const withoutEmail = { name: data.name, password: data.password };
      const missingEmail = await http().post('/user').send(withoutEmail);
      expect(missingEmail.status).toBe(400);

      const shortName = await http()
        .post('/user')
        .send({ ...data, name: 'ab' });
      expect(shortName.status).toBe(400);
    });

    it('cadastra conta básica sem telefone/foto e rejeita campos extras', async () => {
      const data = newUserData();
      const res = await http().post('/user').send(data).expect(201);

      expect(res.body.user).toEqual({
        id: expect.any(String),
        name: data.name,
        email: data.email,
      });
      expect(JSON.stringify(res.body)).not.toMatch(/passwordHash|password"/);

      const extra = await http()
        .post('/user')
        .send({ ...newUserData(), phone: '11999999999' });
      expect(extra.status).toBe(400);
    });

    it('rejeita e-mail duplicado com 409', async () => {
      const data = newUserData();
      await http().post('/user').send(data).expect(201);
      const res = await http().post('/user').send(data);

      expect(res.status).toBe(409);
      expect(res.body.message).toMatch(/Email já está cadastrado/i);
    });

    it('permite login com a senha forte cadastrada após verificar o e-mail', async () => {
      const user = await registerAndVerify('Cadastro#Forte9');
      const res = await login(user.email, user.password).expect(201);
      expect(res.body.accessToken).toBeDefined();
    });
  });

  describe('US-005 / #10 — recuperação de senha', () => {
    async function requestResetToken(email: string) {
      fakeEmail.clear();
      await http().post('/auth/forgot-password').send({ email }).expect(201);
      const code = fakeEmail.getLatestResetCode(email)!;
      const res = await http()
        .post('/auth/verify-reset-code')
        .send({ email, code })
        .expect(201);
      return res.body.resetToken as string;
    }

    it('rejeita código inválido e e-mail inexistente na verificação', async () => {
      const user = await registerAndVerify();
      fakeEmail.clear();
      await http()
        .post('/auth/forgot-password')
        .send({ email: user.email })
        .expect(201);

      const wrong = await http()
        .post('/auth/verify-reset-code')
        .send({ email: user.email, code: 'ZZZZZZ' });
      expect(wrong.status).toBe(400);
      expect(wrong.body.message).toMatch(/Código inválido/i);

      const unknown = await http()
        .post('/auth/verify-reset-code')
        .send({ email: 'ninguem@synthetic.cutmap.test', code: 'ZZZZZZ' });
      expect(unknown.status).toBe(400);
    });

    it('exige o token de redefinição no cabeçalho Authorization', async () => {
      const res = await http()
        .post('/auth/reset-password')
        .send({ newPassword: 'NovaSenha#2026' });
      expect(res.status).toBe(401);
    });

    it('rejeita senha fraca sem consumir o token e conclui com senha forte', async () => {
      const user = await registerAndVerify();
      const resetToken = await requestResetToken(user.email);

      for (const [, weak] of WEAK_PASSWORDS) {
        const res = await http()
          .post('/auth/reset-password')
          .set('Authorization', `Bearer ${resetToken}`)
          .send({ newPassword: weak });
        expect(res.status).toBe(400);
        expect(res.body.message).toContain(STRONG_PASSWORD_MESSAGE);
      }

      // A senha antiga segue válida: nenhuma tentativa fraca foi aplicada.
      await login(user.email, user.password).expect(201);

      const newPassword = 'Recuperada#2026';
      const ok = await http()
        .post('/auth/reset-password')
        .set('Authorization', `Bearer ${resetToken}`)
        .send({ newPassword })
        .expect(201);
      expect(ok.body.message).toMatch(/Senha alterada com sucesso/i);

      await login(user.email, user.password).expect(401);
      await login(user.email, newPassword).expect(201);

      // Política de sessões vigente: o reset revoga os refresh tokens antigos.
      await http()
        .post('/auth/refresh')
        .send({ refreshToken: user.refreshToken })
        .expect(401);

      // Token de uso único.
      const reuse = await http()
        .post('/auth/reset-password')
        .set('Authorization', `Bearer ${resetToken}`)
        .send({ newPassword: 'OutraSenha#2026' });
      expect(reuse.status).toBe(401);
    });
  });

  describe('US-006 / #11 — alteração de senha autenticada (PATCH /user/:id)', () => {
    const newPassword = 'Alterada#2026';

    it('rejeita requisição anônima com 401', async () => {
      const user = await registerAndVerify();
      const res = await http()
        .patch(`/user/${user.id}`)
        .send({ password: newPassword, currentPassword: user.password });
      expect(res.status).toBe(401);
      await login(user.email, user.password).expect(201);
    });

    it.each(WEAK_PASSWORDS)(
      'rejeita nova senha %s com 400 e mantém a senha atual',
      async (_label, weak) => {
        const user = await registerAndVerify();
        const res = await http()
          .patch(`/user/${user.id}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({ password: weak, currentPassword: user.password });

        expect(res.status).toBe(400);
        expect(res.body.message).toContain(STRONG_PASSWORD_MESSAGE);
        await login(user.email, user.password).expect(201);
        await login(user.email, weak).expect(401);
      },
    );

    it('diferencia password ausente (sem troca) de password enviado como null/vazio (400)', async () => {
      const user = await registerAndVerify();
      const patch = (body: Record<string, unknown>) =>
        http()
          .patch(`/user/${user.id}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send(body);

      const absent = await patch({ name: 'Nome Sem Senha' });
      expect(absent.status).toBe(200);
      expect(absent.body.name).toBe('Nome Sem Senha');

      for (const password of [null, '']) {
        const res = await patch({ password, currentPassword: user.password });
        expect(res.status).toBe(400);
        expect(res.body.message).toContain(STRONG_PASSWORD_MESSAGE);
      }

      const nullNoCurrent = await patch({ password: null });
      expect(nullNoCurrent.status).toBe(400);

      await login(user.email, user.password).expect(201);
    });

    it('rejeita senha atual incorreta com 403 e ausente com 400', async () => {
      const user = await registerAndVerify();

      const wrong = await http()
        .patch(`/user/${user.id}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({ password: newPassword, currentPassword: 'Errada#12345' });
      expect(wrong.status).toBe(403);
      expect(wrong.body.message).toMatch(/Senha atual incorreta/i);

      const missing = await http()
        .patch(`/user/${user.id}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({ password: newPassword });
      expect(missing.status).toBe(400);

      await login(user.email, user.password).expect(201);
      await login(user.email, newPassword).expect(401);
    });

    it('bloqueia a troca da senha de outro usuário com 403 sem alterá-la', async () => {
      const attacker = await registerAndVerify();
      const victim = await registerAndVerify();

      const res = await http()
        .patch(`/user/${victim.id}`)
        .set('Authorization', `Bearer ${attacker.accessToken}`)
        .send({ password: newPassword, currentPassword: victim.password });

      expect(res.status).toBe(403);
      expect(res.body.message).toMatch(
        /Não é permitido alterar outro usuário/i,
      );
      await login(victim.email, victim.password).expect(201);
      await login(victim.email, newPassword).expect(401);
    });

    it('permite ao titular trocar a senha e preserva as sessões existentes', async () => {
      const user = await registerAndVerify();
      // Segunda sessão independente (outro aparelho).
      const other = await login(user.email, user.password).expect(201);

      const res = await http()
        .patch(`/user/${user.id}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({ password: newPassword, currentPassword: user.password })
        .expect(200);

      expect(res.body).toEqual({
        id: user.id,
        name: user.name,
        email: user.email,
      });

      await login(user.email, user.password).expect(401);
      await login(user.email, newPassword).expect(201);

      // Nenhuma revogação adicional: access e refresh tokens anteriores seguem válidos.
      await http()
        .get('/user/me')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);
      await http()
        .post('/auth/refresh')
        .send({ refreshToken: other.body.refreshToken })
        .expect(201);
      await http()
        .post('/auth/refresh')
        .send({ refreshToken: user.refreshToken })
        .expect(201);
    });
  });
});
