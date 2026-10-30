import { Argon2Service } from './argon2.service';

describe('Argon2Service', () => {
  it('compara a senha em texto com o hash gerado', async () => {
    const service = new Argon2Service();
    const passwordHash = await service.hash('senha-atual');

    await expect(service.compare('senha-atual', passwordHash)).resolves.toBe(
      true,
    );
    await expect(
      service.compare('senha-incorreta', passwordHash),
    ).resolves.toBe(false);
  });
});
