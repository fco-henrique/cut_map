import {
  BadRequestException,
  Inject,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { LoginDto } from './dto/login.dto';
import { User } from 'src/user/entities/user.entity';
import { IsNull, Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { RefreshToken } from './entities/refresh-token.entity';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { EmailService } from 'src/email/email.service';
import { HashingService } from './hashing/hashing.service';
import {
  AccessTokenPayload,
  RefreshTokenPayload,
} from './interfaces/jwt-payload.interface';
import type { ConfigType } from '@nestjs/config';
import jwtConfig from './config/jwt.config';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,

    @InjectRepository(RefreshToken)
    private readonly refreshRepo: Repository<RefreshToken>,

    private readonly jwtService: JwtService,
    private readonly emailService: EmailService,
    private readonly hashingService: HashingService,

    @Inject(jwtConfig.KEY)
    private readonly jwtConfiguration: ConfigType<typeof jwtConfig>,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.validateUser(dto.email, dto.password);

    const accessToken = await this.generateAccessToken(user);
    const refreshToken = await this.generateRefreshToken(user);

    return { accessToken, refreshToken };
  }

  async validateUser(email: string, password: string) {
    const user = await this.userRepo.findOne({
      where: { email },
      select: ['id', 'email', 'name', 'passwordHash'],
    });
    if (!user) throw new UnauthorizedException('Credenciais inválidas');

    const valid = await this.hashingService.compare(
      user.passwordHash,
      password,
    );
    if (!valid) throw new UnauthorizedException('Credenciais inválidas');

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

  private async generateRefreshToken(user: User) {
    const tokenId = randomUUID();

    const token = await this.jwtService.signAsync(
      { sub: user.id, tokenId, type: 'refresh' },
      { expiresIn: '7d', secret: this.jwtConfiguration.refreshSecret },
    );

    const hash = await this.hashingService.hash(token);

    const entity = this.refreshRepo.create({
      id: tokenId,
      tokenHash: hash,
      user,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    await this.refreshRepo.save(entity);

    return token;
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

    const storedToken = await this.refreshRepo.findOne({
      where: { id: payload.tokenId },
      relations: ['user'],
    });

    if (!storedToken) {
      throw new UnauthorizedException('Token não encontrado ou já revogado.');
    }

    const match = await this.hashingService.compare(
      storedToken.tokenHash,
      token,
    );
    if (!match) {
      throw new UnauthorizedException('Refresh token inválido.');
    }

    if (storedToken.revokedAt) {
      await this.refreshRepo.update(
        { user: { id: storedToken.user.id }, revokedAt: IsNull() },
        { revokedAt: new Date() },
      );
      throw new UnauthorizedException(
        'Sessão comprometida detectada. Faça login novamente.',
      );
    }

    const { affected } = await this.refreshRepo.update(
      { id: storedToken.id, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );

    if (affected !== 1) {
      throw new UnauthorizedException('Refresh token inválido.');
    }

    const accessToken = await this.generateAccessToken(storedToken.user);
    const refreshToken = await this.generateRefreshToken(storedToken.user);

    return { accessToken, refreshToken };
  }

  async verifyEmail(email: string, code: string) {
    const user = await this.userRepo.findOne({
      where: { email },
      select: [
        'id',
        'email',
        'emailVerifiedAt',
        'emailVerificationCode',
        'emailVerificationExpires',
      ],
    });

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
    if (user.emailVerificationCode !== code.trim()) {
      throw new BadRequestException('Código inválido.');
    }

    const accessToken = await this.generateAccessToken(user);
    const refreshToken = await this.generateRefreshToken(user);

    await this.userRepo.update(user.id, {
      emailVerifiedAt: new Date(),
      emailVerificationCode: null,
      emailVerificationExpires: null,
    });

    return {
      message: 'E-mail verificado com sucesso!',
      accessToken,
      refreshToken,
    };
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
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user) {
      return { message: 'Se o e-mail existir, um código será enviado.' };
    }

    const code = this.emailService.generateVerificationCode();
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 15);

    await this.userRepo.update(user.id, {
      resetPasswordCode: code,
      resetPasswordExpires: expires,
    });

    await this.emailService.sendVerificationCode(email, user.name, code);

    return { message: 'Código enviado com sucesso.' };
  }

  async verifyResetCode(email: string, code: string) {
    const user = await this.userRepo.findOne({
      where: { email },
      select: ['id', 'email', 'resetPasswordCode', 'resetPasswordExpires'],
    });

    if (!user) throw new BadRequestException('Usuário não encontrado.');
    if (!user.resetPasswordCode)
      throw new BadRequestException('Nenhum código solicitado.');

    if (user.resetPasswordExpires && new Date() > user.resetPasswordExpires) {
      throw new BadRequestException('Código expirado. Solicite novamente.');
    }

    if (user.resetPasswordCode !== code.trim()) {
      throw new BadRequestException('Código inválido.');
    }

    await this.userRepo.update(user.id, {
      resetPasswordCode: null,
      resetPasswordExpires: null,
    });

    const resetToken = await this.generateResetToken(user);

    return { resetToken };
  }

  async resetPassword(resetToken: string, newPassword: string) {
    try {
      const payload = await this.jwtService.verifyAsync<{
        sub: string;
        purpose: string;
      }>(resetToken, {
        secret: process.env.JWT_RESET_SECRET,
      });

      if (payload.purpose !== 'password_reset') {
        throw new UnauthorizedException('Token inválido para esta operação.');
      }

      const passwordHash = await this.hashingService.hash(newPassword);

      await this.userRepo.update(payload.sub, { passwordHash });

      return { message: 'Senha alterada com sucesso!' };
    } catch {
      throw new UnauthorizedException(
        'Sessão expirada. Solicite um novo código.',
      );
    }
  }
}
