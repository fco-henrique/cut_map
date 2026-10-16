import { UnauthorizedException } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

describe('AuthController', () => {
  const authService = {
    login: jest.fn(),
    refresh: jest.fn(),
    logout: jest.fn(),
    logoutAll: jest.fn(),
    verifyEmail: jest.fn(),
    resendVerificationCode: jest.fn(),
    forgotPassword: jest.fn(),
    verifyResetCode: jest.fn(),
    resetPassword: jest.fn(),
  };
  const controller = new AuthController(authService as unknown as AuthService);

  afterEach(() => jest.clearAllMocks());

  it('encaminha as operações de autenticação com seus argumentos', () => {
    const login = { email: 'user@example.com', password: 'senha123' };
    controller.login(login);
    controller.refresh({ refreshToken: 'refresh-token' });
    controller.logout({ refreshToken: 'refresh-token' });
    controller.logoutAll('user-id');
    controller.verifyEmail({ email: login.email, code: 'ABC123' });
    controller.resendCode({ email: login.email });
    controller.forgotPassword({ email: login.email });
    controller.verifyResetCode({ email: login.email, code: 'ABC123' });

    expect(authService.login).toHaveBeenCalledWith(login);
    expect(authService.refresh).toHaveBeenCalledWith('refresh-token');
    expect(authService.logout).toHaveBeenCalledWith('refresh-token');
    expect(authService.logoutAll).toHaveBeenCalledWith('user-id');
    expect(authService.verifyEmail).toHaveBeenCalledWith(login.email, 'ABC123');
    expect(authService.resendVerificationCode).toHaveBeenCalledWith(
      login.email,
    );
    expect(authService.forgotPassword).toHaveBeenCalledWith(login.email);
    expect(authService.verifyResetCode).toHaveBeenCalledWith(
      login.email,
      'ABC123',
    );
  });

  it('exige Bearer token para redefinir a senha', () => {
    const dto = { newPassword: 'nova-senha' };
    expect(() => controller.resetPassword('', dto)).toThrow(
      UnauthorizedException,
    );
    expect(() => controller.resetPassword('invalid-token', dto)).toThrow(
      UnauthorizedException,
    );
    expect(authService.resetPassword).not.toHaveBeenCalled();
  });

  it('encaminha apenas o token do cabeçalho para redefinir a senha', () => {
    const dto = { newPassword: 'nova-senha' };
    controller.resetPassword('Bearer reset-token', dto);
    expect(authService.resetPassword).toHaveBeenCalledWith(
      'reset-token',
      'nova-senha',
    );
  });
});
