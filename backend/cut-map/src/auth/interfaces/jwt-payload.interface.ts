export type TokenType = 'access' | 'refresh' | 'password_reset';

export interface AccessTokenPayload {
  sub: string;
  email: string;
  name: string;
  type: 'access';
}

export interface RefreshTokenPayload {
  sub: string;
  tokenId: string;
  type: 'refresh';
}

export interface ResetTokenPayload {
  sub: string;
  email: string;
  type: 'password_reset';
  iat: number;
}

export interface AuthenticatedUser {
  sub: string;
  email: string;
  name: string;
}
