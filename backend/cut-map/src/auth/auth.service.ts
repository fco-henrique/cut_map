import { Injectable, UnauthorizedException } from '@nestjs/common';
import { LoginDto } from './dto/login.dto';
import { User } from 'src/user/entities/user.entity';
import { IsNull, Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { RefreshToken } from './entities/refresh-token.entity';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { randomUUID } from 'crypto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,

    @InjectRepository(RefreshToken)
    private refreshRepo: Repository<RefreshToken>,

    private jwtService: JwtService,
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
      select: ['id', 'email', 'passwordHash'],
    });
    if (!user) throw new UnauthorizedException('Credenciais inválidas');

    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) throw new UnauthorizedException('Credenciais inválidas');

    return user;
  }

  private async generateAccessToken(user: User) {
    return this.jwtService.signAsync(
      {
        sub: user.id,
        email: user.email,
      },
      { expiresIn: '15m' },
    );
  }

  private async generateRefreshToken(user: User) {
    const tokenId = randomUUID();

    const token = await this.jwtService.signAsync(
      { sub: user.id, tokenId },
      { expiresIn: '7d' },
    );

    const hash = await argon2.hash(token);

    const entity = this.refreshRepo.create({
      tokenHash: hash,
      user,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    await this.refreshRepo.save(entity);

    return token;
  }

  async refresh(token: string) {
    await this.jwtService.verifyAsync<{ sub: string; tokenId: string }>(token);

    const tokens = await this.refreshRepo.find({
      where: { revokedAt: IsNull() },
      relations: ['user'],
    });

    for (const stored of tokens) {
      const match = await argon2.verify(stored.tokenHash, token);
      if (match) {
        stored.revokedAt = new Date();
        await this.refreshRepo.save(stored);

        const accessToken = await this.generateAccessToken(stored.user);
        const refreshToken = await this.generateRefreshToken(stored.user);

        return { accessToken, refreshToken };
      }
    }

    throw new UnauthorizedException('Invalid refresh token');
  }
}
