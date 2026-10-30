import { EmailService } from './email.service';

describe('EmailService', () => {
  it('gera códigos de seis caracteres com maiúscula, minúscula e número', () => {
    const service = new EmailService();

    for (let i = 0; i < 100; i++) {
      expect(service.generateVerificationCode()).toMatch(
        /^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[A-Za-z0-9]{6}$/,
      );
    }
  });
});
