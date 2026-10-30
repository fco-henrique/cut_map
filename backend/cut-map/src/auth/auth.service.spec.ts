import {
  BadRequestException,
  ForbiddenException,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { Repository } from 'typeorm';
import { AuthService } from './auth.service';
import jwtConfig from './config/jwt.config';
import { RefreshToken } from './entities/refresh-token.entity';
import { HashingService } from './hashing/hashing.service';
import { User } from 'src/user/entities/user.entity';
import { EmailService } from 'src/email/email.service';

jest.mock('argon2', () => ({ hash: jest.fn(), verify: jest.fn() }));

describe('AuthService', () => {
  let service: AuthService;
  let userRepo: jest.Mocked<Pick<Repository<User>, 'findOne' | 'update'>>;
  let refreshRepo: jest.Mocked<
    Pick<Repository<RefreshToken>, 'findOne' | 'update' | 'create' | 'save'>
  >;
  let jwt: jest.Mocked<Pick<JwtService, 'signAsync' | 'verifyAsync'>>;
  let email: jest.Mocked<
    Pick<
      EmailService,
      | 'generateVerificationCode'
      | 'sendVerificationCode'
      | 'sendPasswordResetCode'
    >
  >;
  let hashing: jest.Mocked<Pick<HashingService, 'hash'>>;
  const argonVerify = jest.mocked(argon2.verify);
  const argonHash = jest.mocked(argon2.hash);
  const user = {
    id: 'user-id',
    email: 'user@example.com',
    name: 'Usuário',
    passwordHash: 'stored-hash',
    emailVerifiedAt: new Date('2025-01-01'),
    emailVerificationCode: 'ABC123',
    emailVerificationExpires: new Date(Date.now() + 60_000),
    resetPasswordCode: 'ABC123',
    resetPasswordExpires: new Date(Date.now() + 60_000),
    passwordChangedAt: null,
  } as User;

  beforeEach(() => {
    userRepo = { findOne: jest.fn(), update: jest.fn() };
    refreshRepo = {
      findOne: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };
    jwt = { signAsync: jest.fn(), verifyAsync: jest.fn() };
    email = {
      generateVerificationCode: jest.fn(),
      sendVerificationCode: jest.fn(),
      sendPasswordResetCode: jest.fn(),
    };
    hashing = { hash: jest.fn() };
    service = new AuthService(
      userRepo as unknown as Repository<User>,
      refreshRepo as unknown as Repository<RefreshToken>,
      jwt as unknown as JwtService,
      email as unknown as EmailService,
      hashing as unknown as HashingService,
      {
        refreshSecret: 'refresh-secret',
        resetSecret: 'reset-secret',
        audience: 'cut-map-app',
        issuer: 'cut-map-api',
      } as ConfigType<typeof jwtConfig>,
    );
    userRepo.findOne.mockResolvedValue({ ...user });
    jwt.signAsync
      .mockResolvedValueOnce('access-token')
      .mockResolvedValueOnce('refresh-token');
    argonVerify.mockResolvedValue(true);
    argonHash.mockResolvedValue('token-hash');
    hashing.hash.mockResolvedValue('new-password-hash');
    email.generateVerificationCode.mockReturnValue('ABC123');
    refreshRepo.create.mockImplementation(entity => entity as RefreshToken);
    refreshRepo.save.mockImplementation(async entity => entity as RefreshToken);
    refreshRepo.update.mockResolvedValue({
      affected: 1,
      raw: {},
      generatedMaps: [],
    });
    userRepo.update.mockResolvedValue({
      affected: 1,
      raw: {},
      generatedMaps: [],
    });
  });

  afterEach(() => jest.clearAllMocks());

  describe('login', () => {
    it('valida credenciais e persiste um hash do refresh token', async () => {
      await expect(
        service.login({ email: user.email, password: 'senha' }),
      ).resolves.toEqual({
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      });
      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { email: user.email },
        select: ['id', 'email', 'name', 'passwordHash', 'emailVerifiedAt'],
      });
      expect(argonVerify).toHaveBeenCalledWith(user.passwordHash, 'senha');
      expect(jwt.signAsync).toHaveBeenNthCalledWith(
        1,
        { sub: user.id, email: user.email, name: user.name, type: 'access' },
        {
          expiresIn: '15m',
          audience: 'cut-map-app',
          issuer: 'cut-map-api',
        },
      );
      expect(jwt.signAsync).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          sub: user.id,
          tokenId: expect.any(String),
          type: 'refresh',
        }),
        { expiresIn: '7d', secret: 'refresh-secret' },
      );
      expect(argonHash).toHaveBeenCalledWith('refresh-token');
      expect(refreshRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({
          tokenHash: 'token-hash',
          user: expect.objectContaining({ id: user.id }),
        }),
      );
    });

    it('não emite tokens para usuário inexistente ou senha incorreta', async () => {
      userRepo.findOne.mockResolvedValueOnce(null);
      await expect(
        service.login({ email: user.email, password: 'senha' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      argonVerify.mockResolvedValueOnce(false);
      await expect(
        service.login({ email: user.email, password: 'errada' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(jwt.signAsync).not.toHaveBeenCalled();
    });

    it('exige e-mail verificado depois de validar a senha', async () => {
      userRepo.findOne.mockResolvedValue({ ...user, emailVerifiedAt: null });
      await expect(
        service.login({ email: user.email, password: 'senha' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(argonVerify).toHaveBeenCalledWith(user.passwordHash, 'senha');
      expect(jwt.signAsync).not.toHaveBeenCalled();
    });
  });

  describe('refresh', () => {
    const payload = {
      sub: user.id,
      tokenId: 'token-id',
      type: 'refresh' as const,
    };
    const stored = {
      id: 'token-id',
      tokenHash: 'stored-token-hash',
      user,
      revokedAt: null,
    } as unknown as RefreshToken;

    it('revoga o token usado e emite um novo par', async () => {
      jwt.verifyAsync.mockResolvedValue(payload);
      refreshRepo.findOne.mockResolvedValue(stored);
      await expect(service.refresh('old-token')).resolves.toEqual({
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      });
      expect(jwt.verifyAsync).toHaveBeenCalledWith('old-token', {
        secret: 'refresh-secret',
      });
      expect(argonVerify).toHaveBeenCalledWith(
        'stored-token-hash',
        'old-token',
      );
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { id: 'token-id', revokedAt: expect.anything() },
        { revokedAt: expect.any(Date) },
      );
      expect(refreshRepo.save).toHaveBeenCalled();
    });

    it('rejeita token inválido, tipo errado, ausente e hash divergente', async () => {
      jwt.verifyAsync.mockRejectedValueOnce(new Error('invalid'));
      await expect(service.refresh('bad')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      jwt.verifyAsync.mockResolvedValueOnce({ ...payload, type: 'access' });
      await expect(service.refresh('wrong-type')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      jwt.verifyAsync.mockResolvedValue(payload);
      refreshRepo.findOne.mockResolvedValueOnce(null);
      await expect(service.refresh('missing')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      refreshRepo.findOne.mockResolvedValue(stored);
      argonVerify.mockResolvedValueOnce(false);
      await expect(service.refresh('wrong-hash')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(refreshRepo.update).not.toHaveBeenCalled();
    });

    it('detecta reutilização de token revogado e revoga as demais sessões', async () => {
      jwt.verifyAsync.mockResolvedValue(payload);
      refreshRepo.findOne.mockResolvedValue({
        ...stored,
        revokedAt: new Date(),
      });
      await expect(service.refresh('old-token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { user: { id: user.id }, revokedAt: expect.anything() },
        { revokedAt: expect.any(Date) },
      );
      expect(jwt.signAsync).not.toHaveBeenCalled();
    });

    it('rejeita corrida em que o token já foi consumido', async () => {
      jwt.verifyAsync.mockResolvedValue(payload);
      refreshRepo.findOne.mockResolvedValue(stored);
      refreshRepo.update.mockResolvedValueOnce({
        affected: 0,
        raw: {},
        generatedMaps: [],
      });
      await expect(service.refresh('old-token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(jwt.signAsync).not.toHaveBeenCalled();
    });
  });

  describe('logout', () => {
    it('revoga um refresh token válido e aceita token inválido sem revelar estado', async () => {
      jwt.verifyAsync.mockResolvedValueOnce({
        tokenId: 'token-id',
        type: 'refresh',
      });
      await expect(service.logout('token')).resolves.toEqual({
        message: 'Sessão encerrada.',
      });
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { id: 'token-id' },
        { revokedAt: expect.any(Date) },
      );
      jwt.verifyAsync.mockRejectedValueOnce(new Error('invalid'));
      await expect(service.logout('invalid')).resolves.toEqual({
        message: 'Sessão encerrada.',
      });
      expect(refreshRepo.update).toHaveBeenCalledTimes(1);
    });

    it('revoga todas as sessões do usuário', async () => {
      await service.logoutAll(user.id);
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { user: { id: user.id }, revokedAt: expect.anything() },
        { revokedAt: expect.any(Date) },
      );
    });
  });

  describe('verificação de e-mail', () => {
    it('emite um access token aceito com a audiência e o emissor exigidos', async () => {
      userRepo.findOne.mockResolvedValue({ ...user, emailVerifiedAt: null });
      const realJwt = new JwtService({ secret: 'access-secret' });
      const actualService = new AuthService(
        userRepo as unknown as Repository<User>,
        refreshRepo as unknown as Repository<RefreshToken>,
        realJwt,
        email as unknown as EmailService,
        hashing as unknown as HashingService,
        {
          refreshSecret: 'refresh-secret',
          resetSecret: 'reset-secret',
          audience: 'cut-map-app',
          issuer: 'cut-map-api',
        } as ConfigType<typeof jwtConfig>,
      );

      const result = await actualService.verifyEmail(user.email, 'ABC123');
      expect(
        realJwt.verify(result.accessToken, {
          audience: 'cut-map-app',
          issuer: 'cut-map-api',
        }),
      ).toEqual(expect.objectContaining({ sub: user.id, type: 'access' }));
    });

    it('consome o código e emite tokens', async () => {
      userRepo.findOne.mockResolvedValue({ ...user, emailVerifiedAt: null });
      await expect(service.verifyEmail(user.email, 'ABC123')).resolves.toEqual({
        message: 'E-mail verificado com sucesso!',
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      });
      expect(userRepo.update).toHaveBeenCalledWith(user.id, {
        emailVerifiedAt: expect.any(Date),
        emailVerificationCode: null,
        emailVerificationExpires: null,
      });
    });

    it.each([
      ['usuário ausente', null],
      ['já verificado', { ...user }],
      [
        'sem código',
        { ...user, emailVerifiedAt: null, emailVerificationCode: null },
      ],
      [
        'código expirado',
        {
          ...user,
          emailVerifiedAt: null,
          emailVerificationExpires: new Date(0),
        },
      ],
      ['código errado', { ...user, emailVerifiedAt: null }],
    ])('rejeita %s', async (_case, found) => {
      userRepo.findOne.mockResolvedValue(found as User | null);
      await expect(
        service.verifyEmail(
          user.email,
          _case === 'código errado' ? 'WRONG1' : 'ABC123',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(userRepo.update).not.toHaveBeenCalled();
      expect(jwt.signAsync).not.toHaveBeenCalled();
    });

    it('reenvia código com expiração e trata falha de e-mail', async () => {
      userRepo.findOne.mockResolvedValue({ ...user, emailVerifiedAt: null });
      await expect(service.resendVerificationCode(user.email)).resolves.toEqual(
        { message: 'Novo código enviado.' },
      );
      expect(userRepo.update).toHaveBeenCalledWith(user.id, {
        emailVerificationCode: 'ABC123',
        emailVerificationExpires: expect.any(Date),
      });
      expect(email.sendVerificationCode).toHaveBeenCalledWith(
        user.email,
        user.name,
        'ABC123',
      );
      email.sendVerificationCode.mockRejectedValueOnce(new Error('SMTP'));
      const errorLog = jest
        .spyOn(console, 'error')
        .mockImplementation(() => undefined);
      try {
        await expect(
          service.resendVerificationCode(user.email),
        ).rejects.toBeInstanceOf(InternalServerErrorException);
      } finally {
        errorLog.mockRestore();
      }
    });

    it('não reenvia para usuário ausente ou já verificado', async () => {
      userRepo.findOne.mockResolvedValueOnce(null);
      await expect(
        service.resendVerificationCode(user.email),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        service.resendVerificationCode(user.email),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(email.sendVerificationCode).not.toHaveBeenCalled();
    });
  });

  describe('recuperação de senha', () => {
    it('não revela se o e-mail existe', async () => {
      userRepo.findOne.mockResolvedValueOnce(null);
      const missing = await service.forgotPassword(user.email);
      const existing = await service.forgotPassword(user.email);
      expect(existing).toEqual(missing);
      expect(userRepo.update).toHaveBeenCalledWith(user.id, {
        resetPasswordCode: 'ABC123',
        resetPasswordExpires: expect.any(Date),
      });
      expect(email.sendPasswordResetCode).toHaveBeenCalledWith(
        user.email,
        user.name,
        'ABC123',
      );
    });

    it('propaga falha no envio do código como erro de servidor', async () => {
      email.sendPasswordResetCode.mockRejectedValue(new Error('SMTP'));
      const errorLog = jest
        .spyOn(console, 'error')
        .mockImplementation(() => undefined);
      try {
        await expect(service.forgotPassword(user.email)).rejects.toBeInstanceOf(
          InternalServerErrorException,
        );
      } finally {
        errorLog.mockRestore();
      }
    });

    it('consome o código e emite token de reset com segredo próprio', async () => {
      jwt.signAsync.mockReset().mockResolvedValue('reset-token');
      await expect(
        service.verifyResetCode(user.email, 'ABC123'),
      ).resolves.toEqual({ resetToken: 'reset-token' });
      expect(userRepo.update).toHaveBeenCalledWith(user.id, {
        resetPasswordCode: null,
        resetPasswordExpires: null,
      });
      expect(jwt.signAsync).toHaveBeenCalledWith(
        { sub: user.id, email: user.email, type: 'password_reset' },
        { expiresIn: '10m', secret: 'reset-secret' },
      );
    });

    it('diferencia letras maiúsculas e minúsculas no código de reset', async () => {
      userRepo.findOne.mockResolvedValue({
        ...user,
        resetPasswordCode: 'aBc123',
      });

      await expect(
        service.verifyResetCode(user.email, 'ABC123'),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(userRepo.update).not.toHaveBeenCalled();
    });

    it.each([
      ['usuário ausente', null],
      ['sem código', { ...user, resetPasswordCode: null }],
      ['expirado', { ...user, resetPasswordExpires: new Date(0) }],
      ['incorreto', { ...user }],
    ])('rejeita código %s', async (_case, found) => {
      userRepo.findOne.mockResolvedValue(found as User | null);
      await expect(
        service.verifyResetCode(
          user.email,
          _case === 'incorreto' ? 'WRONG1' : 'ABC123',
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(userRepo.update).not.toHaveBeenCalled();
      expect(jwt.signAsync).not.toHaveBeenCalled();
    });

    it('troca o hash, registra a data e revoga refresh tokens', async () => {
      jwt.verifyAsync.mockResolvedValue({
        sub: user.id,
        email: user.email,
        type: 'password_reset',
        iat: 100,
      });
      const now = new Date();
      await expect(
        service.resetPassword('reset-token', 'nova-senha'),
      ).resolves.toEqual({ message: 'Senha alterada com sucesso!' });
      expect(jwt.verifyAsync).toHaveBeenCalledWith('reset-token', {
        secret: 'reset-secret',
      });
      expect(hashing.hash).toHaveBeenCalledWith('nova-senha');
      expect(userRepo.update).toHaveBeenCalledWith(user.id, {
        passwordHash: 'new-password-hash',
        passwordChangedAt: expect.any(Date),
      });
      expect(
        (
          userRepo.update.mock.calls[0][1] as { passwordChangedAt: Date }
        ).passwordChangedAt.getTime(),
      ).toBeGreaterThanOrEqual(now.getTime());
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { user: { id: user.id }, revokedAt: expect.anything() },
        { revokedAt: expect.any(Date) },
      );
    });

    it('rejeita token inválido, de outro tipo, usuário ausente e token já usado', async () => {
      jwt.verifyAsync.mockRejectedValueOnce(new Error('expired'));
      await expect(
        service.resetPassword('expired', 'nova'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      jwt.verifyAsync.mockResolvedValueOnce({
        sub: user.id,
        type: 'access',
        iat: 100,
      });
      await expect(
        service.resetPassword('wrong-type', 'nova'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      jwt.verifyAsync.mockResolvedValue({
        sub: user.id,
        type: 'password_reset',
        iat: 100,
      });
      userRepo.findOne.mockResolvedValueOnce(null);
      await expect(
        service.resetPassword('missing-user', 'nova'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      userRepo.findOne.mockResolvedValue({
        ...user,
        passwordChangedAt: new Date(100_000),
      });
      await expect(
        service.resetPassword('reused', 'nova'),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(hashing.hash).not.toHaveBeenCalled();
      expect(refreshRepo.update).not.toHaveBeenCalled();
    });
  });
});
