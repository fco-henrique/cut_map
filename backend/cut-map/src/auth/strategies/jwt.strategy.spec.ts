import { UnauthorizedException } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import jwtConfig from '../config/jwt.config';
import type { AccessTokenPayload } from '../interfaces/jwt-payload.interface';
import { JwtStrategy } from './jwt.strategy';

describe('JwtStrategy', () => {
  const config = {
    secret: 'access-secret',
    audience: 'cut-map',
    issuer: 'cut-map',
  } as ConfigType<typeof jwtConfig>;

  it('aceita apenas payload de access token', () => {
    const strategy = new JwtStrategy(config);
    const payload = {
      sub: 'user-id',
      email: 'user@example.com',
      name: 'Usuário',
      type: 'access' as const,
    };

    expect(strategy.validate(payload)).toEqual({
      sub: payload.sub,
      email: payload.email,
      name: payload.name,
    });
    expect(() =>
      strategy.validate({
        ...payload,
        type: 'refresh',
      } as unknown as AccessTokenPayload),
    ).toThrow(UnauthorizedException);
  });

  it('exige segredo JWT configurado', () => {
    expect(() => new JwtStrategy({ ...config, secret: undefined })).toThrow(
      'JWT_SECRET não configurado.',
    );
  });
});
