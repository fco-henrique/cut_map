import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { LoginDto } from './dto/login.dto';
import { User } from 'src/user/entities/user.entity';
import { EntityManager, FindOptionsWhere, IsNull, Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { RefreshToken } from './entities/refresh-token.entity';
import { JwtService } from '@nestjs/jwt';
import { isUUID } from 'class-validator';
import * as argon2 from 'argon2';
import { randomUUID } from 'crypto';
import { EmailService } from 'src/email/email.service';
import { HashingService } from './hashing/hashing.service';
import jwtConfig from './config/jwt.config';
import {
  AccessTokenPayload,
  RefreshTokenPayload,
  ResetTokenPayload,
} from './interfaces/jwt-payload.interface';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,

    private readonly jwtService: JwtService,
    private readonly emailService: EmailService,
    private readonly hashingService: HashingService,

    @Inject(jwtConfig.KEY)
    private readonly jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {}

  async login(dto: LoginDto) {
    return this.withLockedUser(
      { email: dto.email },
      ['id', 'email', 'name', 'passwordHash', 'emailVerifiedAt'],
      async (user, manager) => {
        const authenticated = await this.validateUser(user, dto.password);
        return this.issueSession(authenticated, manager);
      },
    );
  }

  private withLockedUser<T>(
    where: FindOptionsWhere<User>,
    select: (keyof User)[],
    operation: (user: User | null, manager: EntityManager) => Promise<T>,
  ): Promise<T> {
    // Lock the user before reading or writing session or recovery state.
    return this.userRepo.manager.transaction(
      'READ COMMITTED',
      async manager => {
        const user = await manager.getRepository(User).findOne({
          where,
          select,
          lock: { mode: 'pessimistic_write' },
        });
        return operation(user, manager);
      },
    );
  }

  private async validateUser(user: User | null, password: string) {
    if (!user) throw new UnauthorizedException('Credenciais inválidas');

    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) throw new UnauthorizedException('Credenciais inválidas');

    // Só chega aqui com a senha certa, então não há enumeração nova: quem
    // não sabe a senha continua recebendo a mesma "Credenciais inválidas".
    if (!user.emailVerifiedAt) {
      throw new ForbiddenException(
        'E-mail não verificado. Verifique seu e-mail antes de fazer login.',
      );
    }

    return user;
  }

  private async generateResetToken(user: User) {
    return this.jwtService.signAsync(
      {
        sub: user.id,
        email: user.email,
        type: 'password_reset',
      },
      {
        expiresIn: '10m',
        secret: this.jwtConfiguration.resetSecret,
      },
    );
  }

  private async generateAccessToken(user: User) {
    const payload: AccessTokenPayload = {
      sub: user.id,
      email: user.email,
      name: user.name,
      type: 'access',
    };

    return this.jwtService.signAsync(payload, {
      expiresIn: '15m',
      audience: this.jwtConfiguration.audience,
      issuer: this.jwtConfiguration.issuer,
    });
  }

  private async issueSession(user: User, manager: EntityManager) {
    const accessToken = await this.generateAccessToken(user);
    const tokenId = randomUUID();

    const refreshToken = await this.jwtService.signAsync(
      { sub: user.id, tokenId, type: 'refresh' },
      { expiresIn: '7d', secret: this.jwtConfiguration.refreshSecret },
    );

    const tokenHash = await argon2.hash(refreshToken);
    const refreshRepo = manager.getRepository(RefreshToken);
    await refreshRepo.save(
      refreshRepo.create({
        id: tokenId,
        tokenHash,
        user,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      }),
    );

    return { accessToken, refreshToken };
  }

  private revokeSessions(manager: EntityManager, userId: string, now: Date) {
    return manager
      .getRepository(RefreshToken)
      .update(
        { user: { id: userId }, revokedAt: IsNull() },
        { revokedAt: now },
      );
  }

  async refresh(token: string) {
    let payload: RefreshTokenPayload;
    try {
      payload = await this.jwtService.verifyAsync<RefreshTokenPayload>(token, {
        secret: this.jwtConfiguration.refreshSecret,
      });
    } catch {
      throw new UnauthorizedException('Refresh token inválido.');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Token inválido para esta operação.');
    }

    if (!isUUID(payload.sub) || !isUUID(payload.tokenId)) {
      throw new UnauthorizedException('Refresh token inválido.');
    }

    const session = await this.withLockedUser(
      { id: payload.sub },
      ['id', 'email', 'name'],
      async (user, manager) => {
        if (payload.exp <= Math.floor(Date.now() / 1000)) {
          throw new UnauthorizedException('Refresh token inválido.');
        }

        const notFound = 'Token não encontrado ou já revogado.';
        if (!user) throw new UnauthorizedException(notFound);

        const refreshRepo = manager.getRepository(RefreshToken);
        const storedToken = await refreshRepo.findOne({
          where: { id: payload.tokenId, user: { id: user.id } },
        });
        if (!storedToken) throw new UnauthorizedException(notFound);

        const match = await argon2.verify(storedToken.tokenHash, token);
        if (!match) {
          throw new UnauthorizedException('Refresh token inválido.');
        }

        const now = new Date();
        if (storedToken.revokedAt) {
          await this.revokeSessions(manager, user.id, now);
          // Commit the revocation before reporting reuse to the caller.
          return null;
        }

        const { affected } = await refreshRepo.update(
          { id: storedToken.id, revokedAt: IsNull() },
          { revokedAt: now },
        );
        if (affected !== 1) {
          throw new UnauthorizedException('Refresh token inválido.');
        }

        return this.issueSession(user, manager);
      },
    );
    if (!session) {
      throw new UnauthorizedException(
        'Sessão comprometida detectada. Faça login novamente.',
      );
    }
    return session;
  }

  async logout(token: string) {
    const message = 'Sessão encerrada.';
    let payload: RefreshTokenPayload;
    try {
      payload = await this.jwtService.verifyAsync<RefreshTokenPayload>(token, {
        secret: this.jwtConfiguration.refreshSecret,
      });
    } catch {
      return { message };
    }

    if (
      payload.type === 'refresh' &&
      isUUID(payload.sub) &&
      isUUID(payload.tokenId)
    ) {
      await this.withLockedUser(
        { id: payload.sub },
        ['id'],
        async (user, manager) => {
          if (user) {
            await manager.getRepository(RefreshToken).update(
              {
                id: payload.tokenId,
                user: { id: user.id },
                revokedAt: IsNull(),
              },
              { revokedAt: new Date() },
            );
          }
        },
      );
    }
    return { message };
  }

  async logoutAll(userId: string) {
    await this.withLockedUser({ id: userId }, ['id'], async (user, manager) => {
      if (user) {
        await this.revokeSessions(manager, user.id, new Date());
      }
    });

    return { message: 'Todas as sessões foram encerradas.' };
  }

  async verifyEmail(email: string, code: string) {
    return this.withLockedUser(
      { email },
      [
        'id',
        'name',
        'email',
        'emailVerifiedAt',
        'emailVerificationCode',
        'emailVerificationExpires',
      ],
      async (user, manager) => {
        if (!user) throw new BadRequestException('Usuário não encontrado.');
        if (user.emailVerifiedAt)
          throw new BadRequestException('E-mail já verificado.');
        if (!user.emailVerificationCode)
          throw new BadRequestException('Nenhum código pendente.');
        if (
          user.emailVerificationExpires !== null &&
          new Date() > user.emailVerificationExpires
        ) {
          throw new BadRequestException('Código expirado. Solicite um novo.');
        }
        if (user.emailVerificationCode !== code) {
          throw new BadRequestException('Código inválido.');
        }

        await manager.getRepository(User).update(user.id, {
          emailVerifiedAt: new Date(),
          emailVerificationCode: null,
          emailVerificationExpires: null,
        });

        const session = await this.issueSession(user, manager);
        return { message: 'E-mail verificado com sucesso!', ...session };
      },
    );
  }

  async resendVerificationCode(email: string) {
    const user = await this.userRepo.findOne({
      where: { email },
      select: ['id', 'name', 'email', 'emailVerifiedAt'],
    });

    if (!user) throw new BadRequestException('Usuário não encontrado.');
    if (user.emailVerifiedAt)
      throw new BadRequestException('E-mail já verificado.');

    const code = this.emailService.generateVerificationCode();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.userRepo.update(user.id, {
      emailVerificationCode: code,
      emailVerificationExpires: expiresAt,
    });

    try {
      await this.emailService.sendVerificationCode(email, user.name, code);
    } catch (error) {
      console.error('Erro ao reenviar e-mail:', error);
      throw new InternalServerErrorException(
        'Erro ao enviar o e-mail de verificação. Tente novamente mais tarde.',
      );
    }

    return { message: 'Novo código enviado.' };
  }

  async forgotPassword(email: string) {
    const message = 'Se o e-mail existir, um código será enviado.';

    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) {
      return { message };
    }

    const code = this.emailService.generateVerificationCode();
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 15);

    await this.userRepo.update(user.id, {
      resetPasswordCode: code,
      resetPasswordExpires: expires,
    });

    try {
      await this.emailService.sendPasswordResetCode(email, user.name, code);
    } catch (error) {
      console.error('Erro ao enviar e-mail de reset de senha:', error);
      throw new InternalServerErrorException(
        'Erro ao enviar o código de redefinição. Tente novamente mais tarde.',
      );
    }

    return { message };
  }

  async verifyResetCode(email: string, code: string) {
    return this.withLockedUser(
      { email },
      ['id', 'email', 'resetPasswordCode', 'resetPasswordExpires'],
      async (user, manager) => {
        if (!user) throw new BadRequestException('Usuário não encontrado.');
        if (!user.resetPasswordCode)
          throw new BadRequestException('Nenhum código solicitado.');
        if (
          user.resetPasswordExpires &&
          new Date() > user.resetPasswordExpires
        ) {
          throw new BadRequestException('Código expirado. Solicite novamente.');
        }
        if (user.resetPasswordCode !== code) {
          throw new BadRequestException('Código inválido.');
        }

        await manager.getRepository(User).update(user.id, {
          resetPasswordCode: null,
          resetPasswordExpires: null,
        });

        const resetToken = await this.generateResetToken(user);
        return { resetToken };
      },
    );
  }

  async resetPassword(resetToken: string, newPassword: string) {
    const expired = 'Sessão expirada. Solicite um novo código.';
    let payload: ResetTokenPayload;
    try {
      payload = await this.jwtService.verifyAsync<ResetTokenPayload>(
        resetToken,
        { secret: this.jwtConfiguration.resetSecret },
      );
    } catch {
      throw new UnauthorizedException(expired);
    }

    if (payload.type !== 'password_reset') {
      throw new UnauthorizedException('Token inválido para esta operação.');
    }

    if (!isUUID(payload.sub) || !Number.isSafeInteger(payload.iat)) {
      throw new UnauthorizedException(expired);
    }

    return this.withLockedUser(
      { id: payload.sub },
      ['id', 'passwordChangedAt'],
      async (user, manager) => {
        if (!user || payload.exp <= Math.floor(Date.now() / 1000)) {
          throw new UnauthorizedException(expired);
        }

        const issuedAt = payload.iat * 1000;
        if (
          user.passwordChangedAt &&
          issuedAt <= user.passwordChangedAt.getTime()
        ) {
          throw new UnauthorizedException(
            'Este link já foi usado. Solicite um novo código.',
          );
        }

        const passwordHash = await this.hashingService.hash(newPassword);
        const now = new Date();
        // Include the issue time even if another server's clock is ahead.
        const passwordChangedAt = new Date(Math.max(now.getTime(), issuedAt));
        await manager.getRepository(User).update(user.id, {
          passwordHash,
          passwordChangedAt,
        });
        await this.revokeSessions(manager, user.id, now);

        return { message: 'Senha alterada com sucesso!' };
      },
    );
  }
}
