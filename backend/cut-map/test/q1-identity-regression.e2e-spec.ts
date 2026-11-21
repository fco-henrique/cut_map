/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-call */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { EmailService } from 'src/email/email.service';
import { JwtAuthGuard } from 'src/auth/guard/jwt-auth.guard';
import { DockerPostgresHelper } from './helpers/docker-postgres.helper';
import { FakeEmailAdapter } from './helpers/fake-email.adapter';
import { syntheticUsers, syntheticBarbershops } from './helpers/fixtures';

describe('Q1: Regressão HTTP de Titularidade, Sessões Concorrentes e Isolamento', () => {
  let app: INestApplication;
  let dbHelper: DockerPostgresHelper;
  let fakeEmail: FakeEmailAdapter;
  let dataSource: DataSource;

  // Stored session artifacts for synthetic users
  let user1: {
    id: string;
    email: string;
    name: string;
    accessToken: string;
    refreshToken: string;
  };
  let user2: {
    id: string;
    email: string;
    name: string;
    accessToken: string;
    refreshToken: string;
  };
  let user3: {
    id: string;
    email: string;
    name: string;
    accessToken: string;
    refreshToken: string;
  };
  let store1: { id: string; name: string };
  let store2: { id: string; name: string };

  beforeAll(async () => {
    // 1. Isolation barrier: start isolated disposable PostgreSQL container in Docker on loopback
    dbHelper = new DockerPostgresHelper();
    await dbHelper.start();

    // 2. Load AppModule AFTER isolation barrier sets process.env
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { AppModule } = require('src/app.module');

    // 3. Fake email adapter to intercept codes without external network
    fakeEmail = new FakeEmailAdapter();

    // 4. Instantiate real Nest application with overridden email adapter
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(EmailService)
      .useValue(fakeEmail)
      .compile();

    app = moduleFixture.createNestApplication();

    // Attach real Nest ValidationPipe and real JwtAuthGuard
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    const reflector = app.get(Reflector);
    app.useGlobalGuards(new JwtAuthGuard(reflector));

    await app.init();
    dataSource = app.get(DataSource);
  }, 90000);

  afterAll(async () => {
    if (app) {
      await app.close();
    }
    if (dbHelper) {
      dbHelper.stop();
    }
  }, 30000);

  // Helper to register, capture verification code, and verify email
  async function registerAndVerify(userData: {
    name: string;
    email: string;
    password: string;
  }) {
    const regRes = await request(app.getHttpServer())
      .post('/user')
      .send(userData)
      .expect(201);

    const userId = regRes.body.user.id;
    const code = fakeEmail.getLatestVerificationCode(userData.email);
    expect(code).toBeDefined();

    const verifyRes = await request(app.getHttpServer())
      .post('/auth/verify-email')
      .send({ email: userData.email, code })
      .expect(201);

    return {
      id: userId,
      email: userData.email,
      name: userData.name,
      accessToken: verifyRes.body.accessToken as string,
      refreshToken: verifyRes.body.refreshToken as string,
    };
  }

  // =========================================================================
  // CATEGORIA 1: ACESSO ANÔNIMO
  // =========================================================================
  describe('Categoria 1: Acesso Anônimo (Anonymous Access)', () => {
    it('[Q1-ANON-01] GET /user sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer()).get('/user');
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-02] GET /user/me sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer()).get('/user/me');
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-03] PATCH /user/:id sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer())
        .patch('/user/00000000-0000-0000-0000-000000000001')
        .send({ name: 'Hacker' });
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-04] DELETE /user/:id sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer()).delete(
        '/user/00000000-0000-0000-0000-000000000001',
      );
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-05] POST /auth/logout-all sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer()).post('/auth/logout-all');
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-06] GET /barbershops/:id/members sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer()).get(
        '/barbershops/00000000-0000-0000-0000-000000000001/members',
      );
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-07] POST /barbershops/:id/members sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer())
        .post('/barbershops/00000000-0000-0000-0000-000000000001/members')
        .send({
          userId: '00000000-0000-0000-0000-000000000002',
          userRole: 'EMPLOYEE',
        });
      expect(res.status).toBe(401);
    });

    it('[Q1-ANON-08] PATCH /barbershops/:id/members/:userId/role sem autenticação deve retornar 401 Unauthorized', async () => {
      const res = await request(app.getHttpServer())
        .patch(
          '/barbershops/00000000-0000-0000-0000-000000000001/members/00000000-0000-0000-0000-000000000002/role',
        )
        .send({ role: 'MANAGER' });
      expect(res.status).toBe(401);
    });
  });

  // =========================================================================
  // CATEGORIA 2: TITULARIDADE E PROJEÇÕES EM GET /user E /me
  // =========================================================================
  describe('Categoria 2: Titularidade e Projeções em GET /user e /me', () => {
    it('[Setup Contas] Registro e verificação de duas contas sintéticas (Alpha e Beta)', async () => {
      user1 = await registerAndVerify(syntheticUsers.ownerAlpha);
      expect(user1.id).toBeDefined();
      expect(user1.accessToken).toBeDefined();

      user2 = await registerAndVerify(syntheticUsers.ownerBeta);
      expect(user2.id).toBeDefined();
      expect(user2.accessToken).toBeDefined();

      user3 = await registerAndVerify(syntheticUsers.candidateGamma);
      expect(user3.id).toBeDefined();
    });

    it('[Q1-OWN-01] GET /user/me retorna apenas dados do titular sem expor hashes, códigos ou timestamps internos', async () => {
      const res = await request(app.getHttpServer())
        .get('/user/me')
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .expect(200);

      expect(res.body.sub).toBe(user1.id);
      expect(res.body.email).toBe(user1.email);
      expect(res.body.name).toBe(user1.name);

      // Verificação defensiva de não exposição
      expect(res.body.passwordHash).toBeUndefined();
      expect(res.body.emailVerificationCode).toBeUndefined();
      expect(res.body.resetPasswordCode).toBeUndefined();
      expect(res.body.password).toBeUndefined();
    });

    it('[Q1-OWN-02] GET /user retorna projeção estritamente isolada do chamador, nunca expondo outros usuários', async () => {
      const res = await request(app.getHttpServer())
        .get('/user')
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBe(1);
      expect(res.body[0].id).toBe(user1.id);
      expect(res.body[0].email).toBe(user1.email);
      expect(res.body[0].name).toBe(user1.name);

      // Nenhum dado do user2 ou user3 presente
      const ids = res.body.map((u: { id: string }) => u.id);
      expect(ids).not.toContain(user2.id);
      expect(ids).not.toContain(user3.id);

      // Projeção não vaza dados sensíveis
      expect(res.body[0].passwordHash).toBeUndefined();
      expect(res.body[0].emailVerificationCode).toBeUndefined();
    });

    it('[Q1-OWN-03] PATCH /user/:id bloqueia alteração de perfil de outro usuário com 403 Forbidden', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/user/${user2.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ name: 'Nome Invasor' });

      expect(res.status).toBe(403);
      expect(res.body.message).toMatch(
        /Não é permitido alterar outro usuário/i,
      );
    });

    it('[Q1-OWN-04] DELETE /user/:id bloqueia exclusão de perfil de outro usuário com 403 Forbidden', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/user/${user2.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`);

      expect(res.status).toBe(403);
      expect(res.body.message).toMatch(
        /Não é permitido remover outro usuário/i,
      );
    });

    it('[Q1-OWN-05] PATCH /user/:id permite ao titular alterar seu próprio nome e retorna projeção segura', async () => {
      const updatedName = 'Proprietário Alpha Atualizado';
      const res = await request(app.getHttpServer())
        .patch(`/user/${user1.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ name: updatedName })
        .expect(200);

      expect(res.body.id).toBe(user1.id);
      expect(res.body.name).toBe(updatedName);
      expect(res.body.email).toBe(user1.email);
      expect(res.body.passwordHash).toBeUndefined();

      user1.name = updatedName;
    });
  });

  // =========================================================================
  // CATEGORIA 3: ISOLAMENTO DE MEMBROS, PROJEÇÕES E MUDANÇAS DE PAPEL
  // =========================================================================
  describe('Categoria 3: Isolamento de Membros, Projeções e Mudanças de Papel', () => {
    it('[Q1-STORE-01] Criação de duas lojas sintéticas: Store 1 (Alpha) e Store 2 (Beta) com papel OWNER atribuído', async () => {
      const resStore1 = await request(app.getHttpServer())
        .post('/barbershops')
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send(syntheticBarbershops.storeAlpha)
        .expect(201);

      expect(resStore1.body.barbershop.id).toBeDefined();
      expect(resStore1.body.barbershop.name).toBe(
        syntheticBarbershops.storeAlpha.name,
      );
      store1 = {
        id: resStore1.body.barbershop.id,
        name: resStore1.body.barbershop.name,
      };

      const resStore2 = await request(app.getHttpServer())
        .post('/barbershops')
        .set('Authorization', `Bearer ${user2.accessToken}`)
        .send(syntheticBarbershops.storeBeta)
        .expect(201);

      expect(resStore2.body.barbershop.id).toBeDefined();
      store2 = {
        id: resStore2.body.barbershop.id,
        name: resStore2.body.barbershop.name,
      };
    });

    it('[Q1-STORE-02] GET /barbershops/:id retorna detalhes da loja e membros com projeção segura (sem hashes)', async () => {
      // 1. OWNER da própria loja: acessa com sucesso e visualiza membros com projeção segura
      const res = await request(app.getHttpServer())
        .get(`/barbershops/${store1.id}`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .expect(200);

      expect(res.body.barbershop.id).toBe(store1.id);
      expect(res.body.barbershop.name).toBe(store1.name);

      // Verificação estrita de campos autorizados da barbearia
      const authorizedKeys = [
        'id',
        'name',
        'address',
        'phone',
        'description',
        'openingHours',
        'averageRating',
        'totalReviews',
        'members',
      ].sort();
      expect(Object.keys(res.body.barbershop).sort()).toEqual(authorizedKeys);

      const members = res.body.barbershop.members;
      expect(Array.isArray(members)).toBe(true);
      expect(members.length).toBeGreaterThanOrEqual(1);

      for (const m of members) {
        expect(m.user).toBeDefined();
        expect(m.user.id).toBeDefined();
        expect(m.user.name).toBeDefined();
        expect(m.user.passwordHash).toBeUndefined();
        expect(m.user.emailVerificationCode).toBeUndefined();
      }

      // 2. GESTOR DE OUTRA LOJA: loja é visível, mas members retorna []
      const resOtherManager = await request(app.getHttpServer())
        .get(`/barbershops/${store1.id}`)
        .set('Authorization', `Bearer ${user2.accessToken}`)
        .expect(200);
      expect(resOtherManager.body.barbershop.members).toEqual([]);

      // 3. USUÁRIO EXTERNO (sem vínculo com store1): visível, mas members retorna []
      const resExternal = await request(app.getHttpServer())
        .get(`/barbershops/${store1.id}`)
        .set('Authorization', `Bearer ${user3.accessToken}`)
        .expect(200);
      expect(resExternal.body.barbershop.members).toEqual([]);

      // 4. Barretaria inexistente retorna 404 Not Found
      await request(app.getHttpServer())
        .get('/barbershops/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .expect(404);
    });

    it('[Q1-STORE-03] GET /barbershops/:store1Id/members nega acesso ao User 2 (não-membro de Store 1)', async () => {
      const res = await request(app.getHttpServer())
        .get(`/barbershops/${store1.id}/members`)
        .set('Authorization', `Bearer ${user2.accessToken}`);

      // Deve falhar com 401 ou 403 por falta de vínculo com a loja
      expect([401, 403]).toContain(res.status);
    });

    it('[Q1-STORE-04] POST /barbershops/:store1Id/members permite ao OWNER de Store 1 adicionar User 3 como EMPLOYEE', async () => {
      const res = await request(app.getHttpServer())
        .post(`/barbershops/${store1.id}/members`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({
          userId: user3.id,
          userRole: 'EMPLOYEE',
        })
        .expect(201);

      expect(res.body.message).toMatch(/Membro adicionado com sucesso/i);
      expect(res.body.membership.role).toBe('EMPLOYEE');
      expect(res.body.membership.user.id).toBe(user3.id);

      // Validação de contrato: para EMPREGADO, members em GET /barbershops/:id deve retornar []
      const empRes = await request(app.getHttpServer())
        .get(`/barbershops/${store1.id}`)
        .set('Authorization', `Bearer ${user3.accessToken}`)
        .expect(200);
      expect(empRes.body.barbershop.members).toEqual([]);
    });

    it('[Q1-STORE-05] PATCH /barbershops/:store1Id/members/:user3Id/role permite ao OWNER promover EMPLOYEE a MANAGER', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/barbershops/${store1.id}/members/${user3.id}/role`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ role: 'MANAGER' })
        .expect(200);

      expect(res.body.membership.role).toBe('MANAGER');

      // Validação de contrato: para MANAGER da própria loja, members retorna a lista completa
      const mgrRes = await request(app.getHttpServer())
        .get(`/barbershops/${store1.id}`)
        .set('Authorization', `Bearer ${user3.accessToken}`)
        .expect(200);
      expect(Array.isArray(mgrRes.body.barbershop.members)).toBe(true);
      expect(mgrRes.body.barbershop.members.length).toBeGreaterThanOrEqual(2);
    });

    it('[Q1-STORE-06] Gerente (User 3) não pode promover outro membro a gerente (exclusividade do OWNER)', async () => {
      // Cria usuário 4 sintético para testar tentativa de promoção por gerente
      const user4 = await registerAndVerify({
        name: 'Candidato Quatro',
        email: 'user4@synthetic.cutmap.test',
        password: 'Password123!',
      });

      // User 1 adiciona user4 como EMPLOYEE
      await request(app.getHttpServer())
        .post(`/barbershops/${store1.id}/members`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ userId: user4.id, userRole: 'EMPLOYEE' })
        .expect(201);

      // User 3 (MANAGER) tenta promover user4 a MANAGER -> deve ser rejeitado
      const res = await request(app.getHttpServer())
        .patch(`/barbershops/${store1.id}/members/${user4.id}/role`)
        .set('Authorization', `Bearer ${user3.accessToken}`)
        .send({ role: 'MANAGER' });

      expect(res.status).toBe(401);
      expect(res.body.message).toMatch(
        /Apenas o dono pode promover alguém a gerente/i,
      );
    });

    it('[Q1-STORE-07] Gerente (User 3) não pode alterar o cargo do OWNER (retorna 409 Conflict)', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/barbershops/${store1.id}/members/${user1.id}/role`)
        .set('Authorization', `Bearer ${user3.accessToken}`)
        .send({ role: 'EMPLOYEE' });

      expect(res.status).toBe(409);
      expect(res.body.message).toMatch(
        /Não é possível alterar o cargo do dono/i,
      );
    });

    it('[Q1-STORE-08] Tentativa de alterar cargo para o mesmo cargo atual retorna 409 Conflict', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/barbershops/${store1.id}/members/${user3.id}/role`)
        .set('Authorization', `Bearer ${user1.accessToken}`)
        .send({ role: 'MANAGER' });

      expect(res.status).toBe(409);
      expect(res.body.message).toMatch(/já possui o cargo de MANAGER/i);
    });

    it('[Q1-STORE-09] Membro de Store 2 (User 2) é bloqueado ao tentar adicionar membro em Store 1 (403 Forbidden)', async () => {
      const res = await request(app.getHttpServer())
        .post(`/barbershops/${store1.id}/members`)
        .set('Authorization', `Bearer ${user2.accessToken}`)
        .send({ userId: user3.id, userRole: 'EMPLOYEE' });

      expect(store2.id).toBeDefined();
      expect(res.status).toBe(403);
    });
  });

  // =========================================================================
  // CATEGORIA 4: ROTAÇÃO COM CONCORRÊNCIA E DETECÇÃO DE REUSO
  // =========================================================================
  describe('Categoria 4: Rotação com Concorrência e Detecção de Reuso', () => {
    let activeRefreshToken: string;

    beforeEach(async () => {
      // Faz login fresco para obter refresh token limpo (garantindo cadastro prévio se executado isoladamente)
      let loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: syntheticUsers.ownerAlpha.email,
          password: syntheticUsers.ownerAlpha.password,
        });

      if (loginRes.status !== 201) {
        await registerAndVerify(syntheticUsers.ownerAlpha);
        loginRes = await request(app.getHttpServer())
          .post('/auth/login')
          .send({
            email: syntheticUsers.ownerAlpha.email,
            password: syntheticUsers.ownerAlpha.password,
          })
          .expect(201);
      }

      activeRefreshToken = loginRes.body.refreshToken;
    });

    it('[Q1-ROT-01] Rotação legítima de sessão: POST /auth/refresh gera novo par e revoga o anterior', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: activeRefreshToken })
        .expect(201);

      expect(res.body.accessToken).toBeDefined();
      expect(res.body.refreshToken).toBeDefined();
      expect(res.body.refreshToken).not.toBe(activeRefreshToken);
    });

    it('[Q1-ROT-02] Disputa concorrente no refresh: exatamente uma requisição vence e as concorrentes falham com 401', async () => {
      // Dispara 3 requisições simultâneas com o MESMO refresh token
      const promises = [
        request(app.getHttpServer())
          .post('/auth/refresh')
          .send({ refreshToken: activeRefreshToken }),
        request(app.getHttpServer())
          .post('/auth/refresh')
          .send({ refreshToken: activeRefreshToken }),
        request(app.getHttpServer())
          .post('/auth/refresh')
          .send({ refreshToken: activeRefreshToken }),
      ];

      const results = await Promise.all(promises);
      const statuses = results.map(r => r.status);

      const successCount = statuses.filter(s => s === 201 || s === 200).length;
      const failureCount = statuses.filter(s => s === 401).length;

      // Exatamente 1 vence, as demais recebem 401
      expect(successCount).toBe(1);
      expect(failureCount).toBe(2);

      const winningResponse = results.find(
        r => r.status === 201 || r.status === 200,
      );
      expect(winningResponse?.body.accessToken).toBeDefined();
      expect(winningResponse?.body.refreshToken).toBeDefined();
    });

    it('[Q1-ROT-03] Reutilização de token já consumido dispara detecção de comprometimento e revoga todas as sessões', async () => {
      // 1. Executa rotação legítima para consumir activeRefreshToken
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: activeRefreshToken })
        .expect(201);

      // 2. Tenta reutilizar o token anterior já consumido (reuso)
      const reuseRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: activeRefreshToken });

      expect(reuseRes.status).toBe(401);
      expect(reuseRes.body.message).toMatch(/Sessão comprometida detectada/i);
    });

    it('[Q1-ROT-04] Cascata de revogação: sessão sucessora também foi invalidada após detecção de reuso', async () => {
      // Fixtures próprias para execução totalmente autônoma e isolada
      await registerAndVerify(syntheticUsers.rot04User);

      const loginRes = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: syntheticUsers.rot04User.email,
          password: syntheticUsers.rot04User.password,
        })
        .expect(201);

      const initialToken = loginRes.body.refreshToken;

      // 1. Rotação legítima gerando a sessão sucessora
      const rotationRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: initialToken })
        .expect(201);

      const successorRefreshToken = rotationRes.body.refreshToken;

      // 2. Reuso malicioso do token inicial (gatilho de comprometimento)
      const reuseRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: initialToken });

      expect(reuseRes.status).toBe(401);
      expect(reuseRes.body.message).toMatch(/Sessão comprometida detectada/i);

      // 3. Verificação de revogação em cascata da sessão sucessora
      const cascadeRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: successorRefreshToken });

      expect(cascadeRes.status).toBe(401);
    });
  });

  // =========================================================================
  // CATEGORIA 5: RECUPERAÇÃO DE SENHA DE USO ÚNICO
  // =========================================================================
  describe('Categoria 5: Recuperação de Senha de Uso Único', () => {
    let capturedResetCode: string;
    let resetToken: string;
    const recoveryEmail = syntheticUsers.ownerBeta.email;
    const newPassword = 'NovaSenhaUltraSegura2026!';

    it('[Q1-REC-01] POST /auth/forgot-password gera código e entrega via fake email adapter', async () => {
      fakeEmail.clear();

      const res = await request(app.getHttpServer())
        .post('/auth/forgot-password')
        .send({ email: recoveryEmail })
        .expect(201);

      expect(res.body.message).toMatch(/código será enviado/i);

      capturedResetCode = fakeEmail.getLatestResetCode(recoveryEmail)!;
      expect(capturedResetCode).toBeDefined();
      expect(capturedResetCode.length).toBe(6);
    });

    it('[Q1-REC-02] POST /auth/verify-reset-code aceita código válido e retorna resetToken de uso único', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/verify-reset-code')
        .send({ email: recoveryEmail, code: capturedResetCode })
        .expect(201);

      expect(res.body.resetToken).toBeDefined();
      resetToken = res.body.resetToken;
    });

    it('[Q1-REC-03] Reenvio do mesmo código de verificação é rejeitado (400 Bad Request: consumo único)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/verify-reset-code')
        .send({ email: recoveryEmail, code: capturedResetCode });

      expect(res.status).toBe(400);
      expect(res.body.message).toMatch(/Nenhum código solicitado/i);
    });

    it('[Q1-REC-04] POST /auth/reset-password redefine a senha com sucesso usando o resetToken', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/reset-password')
        .set('Authorization', `Bearer ${resetToken}`)
        .send({ newPassword })
        .expect(201);

      expect(res.body.message).toMatch(/Senha alterada com sucesso/i);
    });

    it('[Q1-REC-05] Reutilização do resetToken é rejeitada (401 Unauthorized: consumo único)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/reset-password')
        .set('Authorization', `Bearer ${resetToken}`)
        .send({ newPassword: 'OutraTentativa123!' });

      expect(res.status).toBe(401);
      expect(res.body.message).toMatch(/Este link já foi usado/i);
    });

    it('[Q1-REC-06] Login com senha antiga falha (401) e login com nova senha é bem-sucedido (201)', async () => {
      // Senha antiga deve falhar
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: recoveryEmail,
          password: syntheticUsers.ownerBeta.password,
        })
        .expect(401);

      // Nova senha deve funcionar
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: recoveryEmail, password: newPassword })
        .expect(201);

      expect(res.body.accessToken).toBeDefined();
      expect(res.body.refreshToken).toBeDefined();

      // Atualiza fixture para testes subsequentes
      syntheticUsers.ownerBeta.password = newPassword;
    });
  });

  // =========================================================================
  // CATEGORIA 6: LOGOUT INDIVIDUAL E GLOBAL
  // =========================================================================
  describe('Categoria 6: Logout Individual e Global', () => {
    let sessionDeviceA: { accessToken: string; refreshToken: string };
    let sessionDeviceB: { accessToken: string; refreshToken: string };

    beforeEach(async () => {
      // Cria duas sessões distintas para o mesmo usuário (ex: dois aparelhos)
      const resA = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: syntheticUsers.ownerAlpha.email,
          password: syntheticUsers.ownerAlpha.password,
        })
        .expect(201);

      const resB = await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: syntheticUsers.ownerAlpha.email,
          password: syntheticUsers.ownerAlpha.password,
        })
        .expect(201);

      sessionDeviceA = resA.body;
      sessionDeviceB = resB.body;
    });

    it('[Q1-LOG-01] POST /auth/logout encerra apenas a sessão do token informado, preservando a outra sessão', async () => {
      // Faz logout do Dispositivo A
      const logoutRes = await request(app.getHttpServer())
        .post('/auth/logout')
        .send({ refreshToken: sessionDeviceA.refreshToken })
        .expect(201);

      expect(logoutRes.body.message).toMatch(/Sessão encerrada/i);

      // Dispositivo B continua válido e funcional após logout do Dispositivo A
      const okRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: sessionDeviceB.refreshToken });
      expect(okRes.status).toBe(201);

      // Dispositivo A não consegue renovar pois foi encerrado
      const failRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: sessionDeviceA.refreshToken });
      expect(failRes.status).toBe(401);
    });

    it('[Q1-LOG-02] POST /auth/logout-all encerra todas as sessões ativas do usuário', async () => {
      const logoutAllRes = await request(app.getHttpServer())
        .post('/auth/logout-all')
        .set('Authorization', `Bearer ${sessionDeviceA.accessToken}`)
        .expect(201);

      expect(logoutAllRes.body.message).toMatch(
        /Todas as sessões foram encerradas/i,
      );

      // Ambas as sessões (A e B) devem falhar ao tentar refresh
      const refreshARes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: sessionDeviceA.refreshToken });
      expect(refreshARes.status).toBe(401);

      const refreshBRes = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: sessionDeviceB.refreshToken });
      expect(refreshBRes.status).toBe(401);
    });
  });

  // =========================================================================
  // CATEGORIA 7: REVOGAÇÃO E ROLLBACK EM FALHA CONTROLADA
  // =========================================================================
  describe('Categoria 7: Revogação e Rollback em Falha Controlada', () => {
    it('[Q1-RBK-01] Falha de unicidade em POST /user (código 23505) executa aborto atômico com 409 Conflict', async () => {
      // Tentativa de cadastrar o mesmo e-mail já existente
      const res = await request(app.getHttpServer()).post('/user').send({
        name: 'Duplicata',
        email: syntheticUsers.ownerAlpha.email,
        password: 'Password123!',
      });

      expect(res.status).toBe(409);
      expect(res.body.message).toMatch(/Email já está cadastrado/i);
    });

    it('[Q1-RBK-02] Rollback atômico em transação com falha controlada não deixa dados inconsistentes', async () => {
      const queryRunner = dataSource.createQueryRunner();
      await queryRunner.connect();
      await queryRunner.startTransaction();

      let createdBarbershopId: string | undefined;

      try {
        // Insere barbearia diretamente na transação
        const insertRes = await queryRunner.query(
          `INSERT INTO barbershops (name, "addressCep", "addressRua") VALUES ($1, $2, $3) RETURNING id`,
          ['Barbearia Fantasma Rollback', '01001000', 'Rua Temporária'],
        );
        createdBarbershopId = insertRes[0].id;

        // Simula falha deliberada na transação
        throw new Error('Falha proposital para verificar rollback');
      } catch {
        await queryRunner.rollbackTransaction();
      } finally {
        await queryRunner.release();
      }

      // Verifica se o registro foi revertido do banco de dados
      expect(createdBarbershopId).toBeDefined();
      const checkRes = await dataSource.query(
        `SELECT * FROM barbershops WHERE id = $1`,
        [createdBarbershopId],
      );
      expect(checkRes.length).toBe(0);
    });
  });
});
